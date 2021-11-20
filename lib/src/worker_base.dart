import 'dart:async';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

abstract class WorkerBase {
  Logger? logger;
  Future<StateHead> connect(Uri url);

  /// Returns a new state if state needs to be updated before [start] is called.
  Future<State?> prepare(State state) {
    return Future.value(null);
  }

  Future<Stream<DataBody>> start(State state);
  Future<bool> canResume(StateHead head);
  Future<void> close() async {}
  Future<void> transferCompleted() async {}
}
