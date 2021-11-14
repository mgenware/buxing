import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class Task {
  late final ConnectionBase _conn;
  final String url;
  final String destFile;
  late final Logger? logger;

  Dumper? _dumper;

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
    await dumper.seek(state.downloadedSize);
    logger?.log('task: Dumper position set to: ${state.downloadedSize}');

    logger?.log('task: Starting connection...');
    var dataStream = await _conn.start();

    await for (var bytes in dataStream) {
      logger?.log('task: Bytes received: ${bytes.length}');
      await dumper.writeData(bytes);

      // Update state.
      state.downloadedSize += bytes.length;
      logger?.log('task: Progress: ${state.downloadedSize}/${state.head.size}');

      if (state.downloadedSize > state.head.size) {
        throw Exception(
            'task: Remote file overflow (${state.downloadedSize}/${state.head.size}).');
      }
      if (state.downloadedSize == state.head.size) {
        logger?.log('task: Completing task...');
        await dumper.complete();
      } else {
        await dumper.writeState(state);
      }
    }
  }

  Future close() async {
    _conn.close();
    await _dumper?.close();
  }
}
