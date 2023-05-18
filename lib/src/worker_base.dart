import 'dart:async';

import '../buxing.dart';

/// Base class for all workers.
abstract class WorkerBase {
  /// Logger of this worker.
  Logger? logger;

  /// Connects to server and returns core information about the task, for example, file size.
  Future<StateHead> connect(Uri url);

  /// Returns a new state if state needs to be updated before [start] is called.
  Future<State?> prepare(State state) {
    return Future.value();
  }

  /// Starts data transfer.
  Future<Stream<DataBody>> start(State state);

  /// Checks if server supports requesting a portion of the data.
  Future<bool> canResume(StateHead head);

  /// Closes current worker and releases any resources associated with it.
  Future<void> close() async {}

  /// Called when transfer is completed.
  Future<void> transferCompleted() async {}
}
