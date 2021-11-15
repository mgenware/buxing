import 'dart:async';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

abstract class WorkerBase {
  Logger? logger;
  Future<DataHead> prepare(String url);
  Future<Stream<List<int>>> start();
  Future<bool> canResume();
  void close() {}
}
