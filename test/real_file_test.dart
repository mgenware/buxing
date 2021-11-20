import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'helper/common.dart';

void main() {
  test('Completed successfully (real file)', () async {
    var t = Task(realURL, newFile());
    await t.start();
    await verifyRealFile(t.destFile);
    expect(t.status, TaskStatus.completed);
  });
}
