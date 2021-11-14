import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class TaskProgress {
  final int downloaded;
  final int total;
  TaskProgress(this.downloaded, this.total);
}

class Task {
  final String url;
  final String destFile;
  late final Logger? logger;
  Function(TaskProgress)? onProgress;
  dynamic error;
  bool get closed => _closed;

  late final ConnectionBase _conn;
  Dumper? _dumper;
  bool _closed = false;

  Task(this.url, this.destFile,
      {ConnectionBase? connection, bool logging = false}) {
    _conn = connection ?? Connection();
    if (logging) {
      logger = Logger();
      _conn.logger = logger;
    } else {
      logger = null;
    }
  }

  Future start() async {
    try {
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
      if (head.size != 0) {
        await dumper.seek(state.downloadedSize);
        logger?.log('task: Dumper position set to: ${state.downloadedSize}');
      } else {
        // Empty remote file, complete the task immediately.
        await _complete();
        return;
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
    }
  }

  Future close() async {
    if (closed) {
      return;
    }
    _conn.close();
    await _dumper?.close();
    _closed = true;
  }

  Future _complete() async {
    logger?.log('task: Completing task...');
    await _dumper?.complete();
    _dumper = null;
  }
}
