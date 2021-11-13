import 'dart:async';

import 'package:buxing/src/data.dart';
import 'package:buxing/src/logger.dart';

abstract class ConnectionBase {
  Logger? logger;
  Function(DataHead)? onHeaderReceived;
  Future<Stream<List<int>>> start(String url);
  void close() {}
}
