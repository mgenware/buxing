import 'dart:io';

import 'package:convert/convert.dart';
import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_worker.dart';

Task newTask([WorkerBase? conn]) {
  if (conn == null) {
    var tconn = TWorker();
    tconn.size = defSize;
    conn = tconn;
  }
  var task = Task(defURL, newFile(), worker: conn);
  return task;
}

extension Test on Task {
  Future readDestData() async {
    var bytes = await File(destFile).readAsBytes();
    return hex.encode(bytes);
  }
}

void main() {
  test('Completed successfully with progress', () async {
    var t = newTask();
    List<double> progList = [];
    t.onProgress = (info) {
      progList.add(info.downloaded.toDouble() / info.total);
    };
    await t.start();
    expect(await t.readDestData(), '00000100020003000400');
    expect(progList, [0.2, 0.4, 0.6, 0.8, 1.0]);
    expect(t.status, TaskStatus.completed);
  });

  test('Completed successfully (unknown size)', () async {
    var t = newTask(TWorker()..size = -1);
    List<double> progList = [];
    t.onProgress = (info) {
      progList.add(info.downloaded.toDouble() / info.total);
    };
    await t.start();
    expect(await t.readDestData(), '00000100020003000400');
    expect(progList, [-2.0, -4.0, -6.0, -8.0, -10.0]);
    expect(t.status, TaskStatus.completed);
  });

  test('Completed successfully (empty size)', () async {
    var t = newTask(TWorker()..size = 0);
    List<double> progList = [];
    t.onProgress = (info) {
      progList.add(info.downloaded.toDouble() / info.total);
    };
    await t.start();
    expect(await t.readDestData(), '');
    // ignore: implicit-dynamic, implicit_dynamic_list_literal
    expect(progList, []);
    expect(t.status, TaskStatus.completed);
  });
}
