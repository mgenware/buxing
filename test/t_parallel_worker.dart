import 'package:buxing/buxing.dart';

const pwSize = 40;
const pwNumConns = 4;

class TPWConn extends PWConnBase {
  bool errorMode = false;
  TPWConn(
    Uri url,
    int position,
    int size,
    this.errorMode,
  ) : super(url, position, size);

  @override
  Future<Stream<List<int>>> startCore() async {
    return _getStream();
  }

  @override
  TPWConn create(Uri url, int position, int size) {
    return TPWConn(url, position, size, errorMode);
  }

  Stream<List<int>> _getStream() async* {
    // In error mode, we only send a portion of the data.
    for (int i = 0; i < (errorMode ? 3 : size); i++) {
      yield [i + 1];
    }
  }
}

class TParallelWorker extends ParallelWorker {
  final bool errorMode;
  TParallelWorker({this.errorMode = false}) : super(concurrency: 4);

  static String get s =>
      '0102030405060708090a0102030405060708090a0102030405060708090a0102030405060708090a';

  @override
  Future<DataHead> connect(Uri url) async {
    return Future(() => DataHead(url, url, pwSize));
  }

  @override
  PWConnBase createPWConn(Uri url, ConnState connState) {
    return TPWConn(url, connState.position, connState.size, errorMode);
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
