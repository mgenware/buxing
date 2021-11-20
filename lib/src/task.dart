import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class TaskProgress {
  final int downloaded;
  final int total;
  TaskProgress(this.downloaded, this.total);
}

enum TaskStatus { unstarted, working, completed, error }

class Task {
  final Uri originalURL;
  final String destFile;
  late final Logger? logger;
  Function(TaskProgress)? onProgress;
  Function(State, int)? onBeforeDownload;
  TaskStatus get status => _status;

  late final WorkerBase _worker;
  Dumper? _dumper;
  TaskStatus _status = TaskStatus.unstarted;
  bool _workerClosed = false;
  bool _closed = false;

  String? get stateFile => _dumper?.stateFile.path;
  State? get state => _dumper?.currentState;

  Task(this.originalURL, this.destFile, {WorkerBase? worker, this.logger}) {
    _worker = worker ?? Worker();
    _worker.logger = logger;
  }

  Future<void> start() async {
    try {
      _setStatus(TaskStatus.working);
      logger?.info('task: Starting connection...');
      var head = await _worker.connect(originalURL);
      logger?.info('task: Remote head: ${head.url}:${head.size}');

      // Setup dumper.
      var dumper = await Dumper.loadOrCreate(destFile, head, logger);
      _dumper = dumper;
      logger?.info(
          'task: Dumper created with state:\n${dumper.currentState.toJSON()}\n');
      var state = dumper.currentState;
      if (head.size == 0) {
        // Empty remote file, complete the task immediately.
        await _complete();
        return;
      }
      if (head.size < 0) {
        logger?.info('task: Head.size unknown');
        // Remote size unknown, discard local data, and start from zero.
        await _resetData(state, dumper);
      }

      var canResume = await _worker.canResume(head);
      logger?.info('task: Can resume? $canResume');
      if (canResume) {
        // Set dumper position to last downloaded position.
        await dumper.seek(state.transferred);
        logger?.info('task: Dumper position set to: ${state.transferred}');
      } else {
        // If remove size is unknown, the dumper has been truncated to 0 here.
        // Otherwise, reset dumper position to 0.
        if (head.size > 0) {
          await _resetData(state, dumper);
        }
      }

      logger?.info('task: Preparing...');
      var stateToBeUpdated = await _worker.prepare(state);
      if (stateToBeUpdated != null) {
        logger?.info(
            'task: [prepare] returned state ${stateToBeUpdated.toJSON()}');
        state = stateToBeUpdated;
        await dumper.writeState(state);
      }

      onBeforeDownload?.call(dumper.currentState, dumper.position);
      logger?.info('task: Downloading...');
      var dataStream = await _worker.start(state);

      await for (var body in dataStream) {
        logger?.verbose(
            'task: Body received: ${body.data.length}, poz: ${body.position}');
        var poz = body.position;
        if (poz != null) {
          logger?.verbose('task: Seek: $poz');
          await dumper.seek(poz);
        }
        await dumper.writeData(body.data);

        // Update state.
        state.transferred += body.data.length;
        onProgress?.call(TaskProgress(state.transferred, head.size));
        logger?.verbose('task: Progress: ${state.transferred}/${head.size}');

        if (head.size >= 0 && state.transferred > head.size) {
          throw Exception(
              'task: Remote file overflow (${state.transferred}/${head.size}).');
        }
        if (state.transferred == head.size) {
          await _complete();
          return;
        } else {
          await dumper.writeState(state);
        }
      }
      await _worker.transferCompleted();
      await _closeWorker();

      logger?.info('task: Data transfer done');
      // Complete the task if remote size is unknown.
      if (head.size == -1) {
        await _complete();
      } else {
        await close();
      }
    } catch (ex) {
      _setStatus(TaskStatus.error);
      logger?.error('task: FATAL: $ex');
      await close();
      rethrow;
    }
  }

  /// Releases any resources of the current dumper.
  Future<void> close() async {
    // This check is necessary as [complete] might have called [close].
    if (_closed) {
      return;
    }
    await _closeWorker();
    ;
    await _dumper?.close();
    _closed = true;
  }

  Future<void> _complete() async {
    _setStatus(TaskStatus.completed);
    logger?.info('task: Completing task...');
    await _dumper!.complete();
    _dumper = null;
    await close();
  }

  Future<void> _resetData(State state, Dumper dumper) async {
    logger?.info('task: Resetting task...');
    state.transferred = 0;
    await dumper.writeState(state);
    await dumper.seek(0);
    await dumper.truncate(0);
  }

  void _setStatus(TaskStatus status) {
    if (status.index <= _status.index) {
      throw Exception('Invalid status change from $_status to $status');
    }
    _status = status;
  }

  Future<void> _closeWorker() async {
    if (_workerClosed) {
      return;
    }
    _workerClosed = true;
    await _worker.close();
  }
}
