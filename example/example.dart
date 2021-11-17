// ignore_for_file: avoid_print

import 'package:buxing/buxing.dart';

void main() async {
  var task = Task(
      Uri.parse('https://www.apache.org/img/asf-estd-1999-logo.jpg'),
      'test.jpg',
      logging: true);
  await task.start();
}
