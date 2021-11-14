import 'dart:io';

import 'package:convert/convert.dart';
import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_conn.dart';

Task newTask(bool hasError) {
  var conn = TConn();
  conn.size = defSize;
  var task = Task(defURL, newFile(), connection: conn);
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
    var t = newTask(false);
    List<double> progList = [];
    t.onProgress = (info) {
      progList.add(info.downloaded.toDouble() / info.total);
    };
    await t.start();
    expect(await t.readDestData(), '00000100020003000400');
    expect(progList, [0.2, 0.4, 0.6, 0.8, 1.0]);
  });

  test('Pause and resume', () async {
    Task? t;
    for (var i = 0; i < 5; i++) {
      t = newTask(false);
      await t.start();
    }
    expect(await t?.readDestData(), '00000100020003000400');
  });
}
