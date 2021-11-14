import 'dart:async';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

abstract class ConnectionBase {
  Logger? logger;
  Future<DataHead> prepare(String url);
  Future<Stream<List<int>>> start();
  void close() {}
}
