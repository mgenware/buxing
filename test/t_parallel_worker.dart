import 'package:buxing/buxing.dart';

const pwSize = 43;
const pwNumConns = 4;

class TConn extends ConnBase {
  bool errorMode = false;
  TConn(
    StateHead head,
    ConnState connState,
    this.errorMode,
  ) : super(head, connState);

  @override
  Future<Stream<List<int>>> startCore() async {
    return _getStream();
  }

  Stream<List<int>> _getStream() async* {
    // In error mode, we only send a portion of the data.
    for (int i = initialState.start;
        i <= (errorMode ? initialState.start + 3 : initialState.end);
        i++) {
      yield [i + 1];
    }
  }
}

class TParallelWorker extends ParallelWorker {
  final bool errorMode;
  final bool partialDone;
  TParallelWorker({this.errorMode = false, this.partialDone = false})
      : super(concurrency: 4);

  static String get s =>
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b';

  @override
  Future<StateHead> connect(Uri url) async {
    return Future(() => StateHead(url, url, pwSize));
  }

  @override
  ConnBase spawnConn(StateHead head, ConnState connState) {
    return TConn(head, connState, errorMode);
  }

  @override
  Future<bool> canResume(StateHead head) {
    return Future.value(true);
  }

  @override
  Future<void> transferCompleted() async {
    if (errorMode) {
      throw Exception('Intentional exception');
    }
  }
}
