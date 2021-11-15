import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class TaskProgress {
  final int downloaded;
  final int total;
  TaskProgress(this.downloaded, this.total);
}

enum TaskStatus { unstarted, working, paused, completed, error }

class Task {
  final String url;
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
    _conn = connection ?? ResumableWorker();
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
      logger?.log('task: Preparing connection...');
      var head = await _conn.prepare(url);
      logger?.log('task: Remote head: ${head.actualURL}:${head.size}');

      // Setup dumper.
      var dumper = await Dumper.loadOrCreate(destFile, head, logger);
      _dumper = dumper;
      logger?.log(
          'task: Dumper created with state:\n${dumper.currentState.toJSON()}\n');
      // Set dumper position to last downloaded position.
      var state = dumper.currentState;
      if (head.size == 0) {
        // Empty remote file, complete the task immediately.
        await _complete();
        return;
      } else if (head.size > 0) {
        var canResume = await _conn.canResume();
        logger?.log('task: Can resume? $canResume');
        if (canResume) {
          await dumper.seek(state.downloadedSize);
          logger?.log('task: Dumper position set to: ${state.downloadedSize}');
        } else {
          await _resetData(state, dumper);
        }
      } else {
        logger?.log('task: Head.size unknown');
        await _resetData(state, dumper);
      }

      logger?.log('task: Starting connection...');
      var dataStream = await _conn.start();

      await for (var bytes in dataStream) {
        logger?.log('task: Bytes received: ${bytes.length}');
        await dumper.writeData(bytes);

        // Update state.
        state.downloadedSize += bytes.length;
        onProgress?.call(TaskProgress(state.downloadedSize, head.size));
        logger?.log('task: Progress: ${state.downloadedSize}/${head.size}');

        if (head.size >= 0 && state.downloadedSize > head.size) {
          throw Exception(
              'task: Remote file overflow (${state.downloadedSize}/${head.size}).');
        }
        if (state.downloadedSize == head.size) {
          logger?.log('task: Completing task...');
          await _complete();
        } else {
          await dumper.writeState(state);
        }
      }

      logger?.log('task: Data transfer done');
      // Complete the task if remote size is unknown.
      if (head.size == -1) {
        await _complete();
      } else {
        await close();
      }
    } catch (ex) {
      logger?.log('task: FATAL: $ex');
      await close();
      error = ex;
      _setStatus(TaskStatus.error);
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
    logger?.log('task: Completing task...');
    await _dumper!.complete();
    _dumper = null;
    _setStatus(TaskStatus.completed);
  }

  Future _resetData(State state, Dumper dumper) async {
    logger?.log('task: Resetting task...');
    state.downloadedSize = 0;
    await dumper.writeState(state);
    await dumper.clearData();
  }

  void _setStatus(TaskStatus status) {
    if (_status == status) {
      throw Exception('Invalid status change');
    }
    _status = status;
  }
}
