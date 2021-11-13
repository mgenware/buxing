import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

class Task {
  late final ConnectionBase _conn;
  final String url;
  final String destFile;
  void Function(dynamic)? onDone;
  late final Logger? logger;

  State? _state;
  Dumper? _dumper;

  Task(this.url, this.destFile,
      {ConnectionBase? connection, bool logging = false}) {
    _conn = connection ?? Connection();
    if (logging) {
      logger = Logger();
      _conn.logger = logger;
    }
  }

  Future start() async {
    _conn.onHeaderReceived = (head) async {
      logger?.log('onHead: ${head.actualURL}|${head.size}');
      var state = State(head);
      _state = state;
      _dumper = await Dumper.loadOrCreate(destFile, state, logger: logger);
    };

    logger?.log('Starting connection...');
    var dataStream = await _conn.start(url);
    await for (var bytes in dataStream) {
      logger?.log('bytes received: ${bytes.length}');
      await _dumper?.writeData(bytes);

      // Update state.
      _state!.downloadedSize += bytes.length;
      await _dumper?.writeState(_state!);
    }
  }

  void close() {
    _conn.close();
  }
}
