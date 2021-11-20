import 'package:buxing/buxing.dart';

const pwSize = 40;
const pwNumConns = 4;

class TPWConn extends PWConnBase {
  bool errorMode = false;
  TPWConn(
    Uri url,
    ConnState connState,
    this.errorMode,
  ) : super(url, connState);

  @override
  Future<Stream<List<int>>> startCore() async {
    return _getStream();
  }

  @override
  TPWConn create(Uri url, ConnState connState) {
    return TPWConn(url, connState, errorMode);
  }

  Stream<List<int>> _getStream() async* {
    // In error mode, we only send a portion of the data.
    // [connState] changes during transfer, cache its values first.
    var start = connState.start;
    var end = connState.end;

    for (int i = start; i <= (errorMode ? start + 3 : end); i++) {
      yield [i + 1];
    }
  }
}

class TParallelWorker extends ParallelWorker {
  final bool errorMode;
  TParallelWorker({this.errorMode = false}) : super(concurrency: 4);

  static String get s =>
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728';

  @override
  Future<DataHead> connect(Uri url) async {
    return Future(() => DataHead(url, url, pwSize));
  }

  @override
  PWConnBase createPWConn(Uri url, ConnState connState) {
    return TPWConn(url, connState, errorMode);
  }

  @override
  Future<bool> canResume(Uri url) {
    return Future.value(true);
  }

  @override
  Future<void> transferCompleted() async {
    if (errorMode) {
      throw Exception('Intentional exception');
    }
  }
}
