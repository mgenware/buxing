import 'package:buxing/buxing.dart';

const pwSize = 43;
const pwNumConns = 4;

class TConn extends ConnBase {
  // In full pause mode, all connections are paused.
  bool fullPause;

  /// In partial pause mode, some connections are completed while others are paused.
  bool partialPause;

  TConn(StateHead head, ConnState connState,
      {this.fullPause = false, this.partialPause = false})
      : super(head, connState);

  @override
  Future<Stream<List<int>>> startCore() async {
    return _getStream();
  }

  Stream<List<int>> _getStream() async* {
    var start = initialState.start;
    var end =
        (fullPause || partialPause) ? initialState.start + 3 : initialState.end;
    if (partialPause && (id == '1' || id == '3')) {
      end = initialState.end;
    }
    // In error mode, we only send a portion of the data.
    for (int i = start; i <= end; i++) {
      yield [i + 1];
    }
  }
}

class TParallelWorker extends ParallelWorker {
  final bool fullPause;
  final bool partialPause;
  TParallelWorker({this.fullPause = false, this.partialPause = false})
      : super(concurrency: 4);

  static String get s =>
      '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b';

  @override
  Future<StateHead> connect(Uri url) async {
    return Future.value(StateHead(url, url, pwSize));
  }

  @override
  ConnBase spawnConn(StateHead head, ConnState connState) {
    return TConn(head, connState,
        fullPause: fullPause, partialPause: partialPause);
  }

  @override
  Future<bool> canResume(StateHead head) {
    return Future.value(true);
  }

  @override
  Future<void> transferCompleted() async {
    if (partialPause || fullPause) {
      throw Exception('Intentional exception');
    }
  }
}
