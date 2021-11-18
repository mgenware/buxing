import 'dart:io';

import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_parallel_worker.dart';

Task newPTask([WorkerBase? conn]) {
  if (conn == null) {
    var tconn = TParallelWorker();
    conn = tconn;
  }
  var task = Task(defURL, newFile(), worker: conn);
  return task;
}

extension Test on Task {
  Future<String> readDestString() async {
    return File(destFile).readAsString();
  }
}

void main() {
  test('Completed successfully with progress', () async {
    var t = newPTask();
    List<int> progList = [];
    t.onProgress = (info) {
      progList.add((info.downloaded.toDouble() / info.total * 100).round());
    };
    await t.start();
    expect(await t.readDestString(), pwString);
    expect(progList.every((e) => e > 0 && e <= 100), true);
    expect(t.status, TaskStatus.completed);
  });
}
