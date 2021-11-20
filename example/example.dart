import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

void main() async {
  var task = Task(
      Uri.parse('https://coldfunction.com/dds/ua/103/50_nNZqOS.png'), 'a.png',
      logger: Logger());
  await task.start();
}
