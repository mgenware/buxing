import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class TaskProgress {
  final int downloaded;
  final int total;
  TaskProgress(this.downloaded, this.total);
}

enum TaskStatus { unstarted, working, paused, completed, error }

class Task {
  final Uri url;
  final String destFile;
  late final Logger? logger;
  Function(TaskProgress)? onProgress;
  dynamic error;
  TaskStatus get status => _status;

  late final WorkerBase _conn;
  Dumper? _dumper;
  TaskStatus _status = TaskStatus.unstarted;
  bool _closed = false;

  Task(this.url, this.destFile,
      {WorkerBase? connection, bool logging = false}) {
    _conn = connection ?? Worker();
    if (logging) {
      logger = Logger();
      _conn.logger = logger;
    } else {
      logger = null;
    }
  }

  Future start() async {
    try {
      _setStatus(TaskStatus.working);
      logger?.info('task: Starting connection...');
      var head = await _conn.connect(url);
      logger?.info('task: Remote head: ${head.actualURL}:${head.size}');

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

      var canResume = await _conn.canResume();
      logger?.info('task: Can resume? $canResume');
      if (canResume) {
        // Set dumper position to last downloaded position.
        await dumper.seek(state.downloadedSize);
        logger?.info('task: Dumper position set to: ${state.downloadedSize}');
      } else {
        // If remove size is unknown, the dumper has been truncated to 0 here.
        // Otherwise, reset dumper position to 0.
        if (head.size > 0) {
          await dumper.seek(0);
        }
      }

      logger?.info('task: Preparing...');
      var stateToBeUpdated = await _conn.prepare(state);
      if (stateToBeUpdated != null) {
        state = stateToBeUpdated;
        await dumper.writeState(state);
      }

      logger?.info('task: Downloading...');
      var dataStream = await _conn.start(url, state);

      await for (var body in dataStream) {
        logger?.info(
            'task: Body received: ${body.data.length}(${body.position})');
        await dumper.writeData(body.data);

        // Update state.
        state.downloadedSize += body.data.length;
        onProgress?.call(TaskProgress(state.downloadedSize, head.size));
        logger?.info('task: Progress: ${state.downloadedSize}/${head.size}');

        if (head.size >= 0 && state.downloadedSize > head.size) {
          throw Exception(
              'task: Remote file overflow (${state.downloadedSize}/${head.size}).');
        }
        if (state.downloadedSize == head.size) {
          await _complete();
          return;
        } else {
          await dumper.writeState(state);
        }
      }

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
      error = ex;
    }
  }

  /// Releases any resources of the current dumper.
  Future close() async {
    // This check is necessary as [complete] might have called [close].
    if (_closed) {
      return;
    }
    _conn.close();
    await _dumper?.close();
    _closed = true;
  }

  Future _complete() async {
    _setStatus(TaskStatus.completed);
    logger?.info('task: Completing task...');
    await _dumper!.complete();
    _dumper = null;
  }

  Future _resetData(State state, Dumper dumper) async {
    logger?.info('task: Resetting task...');
    state.downloadedSize = 0;
    await dumper.writeState(state);
    await dumper.truncate(0);
  }

  void _setStatus(TaskStatus status) {
    if (_status == status) {
      throw Exception('Invalid status change');
    }
    _status = status;
  }
}
