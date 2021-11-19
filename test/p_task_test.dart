import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_parallel_worker.dart';

void main() {
  test('Completed successfully with progress', () async {
    var t = TaskWrapper(worker: TParallelWorker());
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":774,"downloaded_size":0,"conn":[{"position":0,"downloaded_size":0,"size":155},{"position":155,"downloaded_size":0,"size":155},{"position":310,"downloaded_size":0,"size":155},{"position":465,"downloaded_size":0,"size":155},{"position":620,"downloaded_size":0,"size":154}]}');
    expect(await t.readDestString(), pwString);
    expect(t.progressValues.every((e) => e > 0 && e <= 100), true);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });
}
