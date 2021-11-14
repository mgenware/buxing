// ignore_for_file: avoid_print

import 'package:buxing/buxing.dart';

void main() async {
  var task =
      Task('https://www.apache.org/foundation/', 'test.html', logging: true);
  await task.start();
}
