import 'dart:async';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

abstract class WorkerBase {
  Logger? logger;
  Future<DataHead> connect(Uri url);

  /// Returns a new state if state needs to be updated before [start] is called.
  Future<State?> prepare(State state) {
    return Future(() => null);
  }

  Future<Stream<DataBody>> start(Uri url, State state);
  Future<bool> canResume();
  void close() {}
}
