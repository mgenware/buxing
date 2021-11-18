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
  Future<DataHead> connect(Uri url) async {
    return Future(() => DataHead(url, url, size));
  }

  @override
  Future<Stream<DataBody>> start(Uri url, State state) async {
    return Future(() => _getStream());
  }

  @override
  Future<bool> canResume(Uri url) async {
    return Future(() => canResumeValue);
  }

  Stream<DataBody> _getStream() async* {
    if (size == 0) {
      return;
    }
    if (segment != -1) {
      yield DataBody([segment, 0]);
    } else {
      for (int i = 0; i < 5; i++) {
        if (streamError && i == 3) {
          throw Exception('Intentional exception');
        }
        yield DataBody([i, 0]);
      }
    }
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}
