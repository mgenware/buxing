import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class TaskProgress {
  final int downloaded;
  final int total;
  TaskProgress(this.downloaded, this.total);
}

enum TaskStatus { unstarted, working, completed, stopped }

class Task {
  final Uri url;
  final String destFile;
  late final Logger? logger;
  Function(TaskProgress)? onProgress;
  TaskStatus get status => _status;

  late final WorkerBase _conn;
  Dumper? _dumper;
  TaskStatus _status = TaskStatus.unstarted;

  bool get isCompletedOrStopped => _dumper == null;
  String? get stateFile => _dumper?.stateFile.path;
  State? get state => _dumper?.currentState;

  Task(this.url, this.destFile, {WorkerBase? worker, this.logger}) {
    _conn = worker ?? Worker();
  }

  Future<void> start() async {
    try {
      //
      // Important: Always use the optional [_dumper] cuz [_dumper] may be null as a
      // result of calling [stop].
      //
      _setStatus(TaskStatus.working);
      await _connect();
      await _prepare();
      await _download();
    } catch (ex) {
      _setStatus(TaskStatus.stopped);
      logger?.error('task: FATAL: $ex');
      await close();
      rethrow;
    }
  }

  Future<void> stop() async {
    _setStatus(TaskStatus.stopped);
    await close();
  }

  /// Releases any resources of the current dumper.
  Future<void> close() async {
    // This check is necessary as [complete] might have called [close].
    if (isCompletedOrStopped) {
      return;
    }
    await _conn.close();
    await _dumper?.close();
  }

  Future<void> _complete() async {
    if (isCompletedOrStopped) {
      return;
    }
    _setStatus(TaskStatus.completed);
    logger?.info('task: Completing task...');
    await _dumper?.complete();
    _dumper = null;
  }

  void _setStatus(TaskStatus status) {
    if (isCompletedOrStopped) {
      return;
    }
    if (status.index <= _status.index) {
      throw Exception('Invalid status change from $_status to $status');
    }
    _status = status;
  }

  Future<void> _connect() async {
    logger?.info('task: Starting connection...');
    var head = await _conn.connect(url);
    logger?.info('task: Remote head: ${head.actualURL}:${head.size}');

    // Setup dumper.
    _dumper = await Dumper.loadOrCreate(destFile, head, logger);
    logger?.info(
        'task: Dumper created with state:\n${_dumper!.currentState.toJSON()}\n');
    if (head.size == 0) {
      // Empty remote file, complete the task immediately.
      await _complete();
      return;
    }
    if (head.size < 0) {
      logger?.info('task: Head.size unknown');
      // Remote size unknown, discard local data, and start from zero.
      logger?.info('task: Resetting task...');
      await _dumper?.close();
      _dumper = await Dumper.create(destFile, head);
    }

    var canResume = await _conn.canResume(url);
    logger?.info('task: Can resume? $canResume');
    if (canResume) {
      // Set dumper position to last downloaded position.
      await _dumper?.seek(_dumper?.currentState.downloadedSize ?? 0);
      logger?.info(
          'task: Dumper position set to: ${_dumper?.currentState.downloadedSize}');
    } else {
      // If remove size is unknown, the dumper has been truncated to 0 here.
      // Otherwise, reset dumper position to 0.
      if (head.size > 0) {
        await _dumper?.seek(0);
      }
    }
  }

  Future<void> _prepare() async {
    if (_dumper == null) {
      return;
    }
    logger?.info('task: Preparing...');
    var stateToBeUpdated = await _conn.prepare(_dumper!.currentState);
    if (stateToBeUpdated != null) {
      await _dumper?.writeState(stateToBeUpdated);
    }
  }

  Future<void> _download() async {
    var dumper = _dumper;
    if (dumper == null) {
      return;
    }
    logger?.info('task: Downloading...');
    var state = dumper.currentState;
    var head = state.head;
    var dataStream = await _conn.start(url, state);

    await for (var body in dataStream) {
      logger?.verbose(
          'task: Body received: ${body.data.length}(${body.position})');
      var poz = body.position;
      if (poz != null) {
        logger?.verbose('task: Seek: $poz');
        await dumper.seek(poz);
      }
      await dumper.writeData(body.data);

      // Update state.
      state.downloadedSize += body.data.length;
      onProgress?.call(TaskProgress(state.downloadedSize, head.size));
      logger?.verbose('task: Progress: ${state.downloadedSize}/${head.size}');

      if (head.size > 0 && state.downloadedSize > head.size) {
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
  }
}
