import 'dart:async';

import 'package:buxing/buxing.dart';

class TWorker extends WorkerBase {
  var closed = false;
  bool streamError = false;
  bool headError = false;
  int size = -1;
  int startPoz = 0;
  bool canResumeValue = true;

  static String get s => '0102030405060708090a';

  @override
  Future<DataHead> connect(Uri url) async {
    if (headError) {
      throw Exception('Intentional head exception');
    }
    return Future(() => DataHead(url, url, size));
  }

  @override
  Future<Stream<DataBody>> start(Uri url, State state) async {
    if (state.transferred > 0) {
      startPoz = state.transferred;
    }
    return Future(() => _getStream());
  }

  @override
  Future<bool> canResume(Uri url) async {
    return Future.value(canResumeValue);
  }

  Stream<DataBody> _getStream() async* {
    if (size == 0) {
      return;
    }
    if (startPoz > 0) {
      for (int i = startPoz; i < 10; i++) {
        yield DataBody([i + 1]);
      }
      return;
    }
    var poz = 0;
    for (int i = 0; i < 5; i++) {
      if (streamError && i == 3) {
        throw Exception('Intentional body exception');
      }
      yield DataBody([_getByte(poz++), _getByte(poz++)]);
    }
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  int _getByte(int poz) {
    return poz + 1;
  }
}
