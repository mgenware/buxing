import 'dart:async';

import 'package:buxing/buxing.dart';

class TWorker extends WorkerBase {
  var closed = false;
  bool streamError = false;
  bool headError = false;
  int size = -1;
  int segment = -1;
  bool canResumeValue = true;

  @override
  Future<DataHead> prepare(String url) async {
    return Future(() => DataHead(url, url, size));
  }

  @override
  Future<Stream<List<int>>> start() async {
    return Future(() => _getStream());
  }

  @override
  Future<bool> canResume() async {
    return Future(() => canResumeValue);
  }

  Stream<List<int>> _getStream() async* {
    if (size == 0) {
      return;
    }
    if (segment != -1) {
      yield [segment, 0];
    } else {
      for (int i = 0; i < 5; i++) {
        if (streamError && i == 3) {
          throw Exception('Intentional exception');
        }
        yield [i, 0];
      }
    }
  }

  @override
  void close() {
    closed = true;
  }
}
