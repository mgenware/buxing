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
  test('Completed successfully, progress', () async {
    var t = newTask(false);
    await t.start();
    await t.close();
    expect(await t.readDestData(), '00000000000000000000');
  });
}
