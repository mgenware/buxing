import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

void main() async {
  var task = Task(
      Uri.parse('https://golang.org/dl/go1.17.3.src.tar.gz'), 'a.zip',
      worker: ParallelWorker(), logger: Logger(level: LogLevel.info));
  await task.start();
}
