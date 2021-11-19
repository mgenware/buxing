import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_parallel_worker.dart';

void main() {
  test('Completed successfully with progress', () async {
    var t = TaskWrapper(worker: TParallelWorker());
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":40,"downloaded_size":0,"conn":[{"position":0,"downloaded_size":0,"size":10},{"position":10,"downloaded_size":0,"size":10},{"position":20,"downloaded_size":0,"size":10},{"position":30,"downloaded_size":0,"size":10}]}');
    expect(await t.readDestData(), TParallelWorker.s);
    expect(t.progressValues.every((e) => e > 0 && e <= 100), true);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Body error and resume', () async {
    var t = TaskWrapper(worker: TParallelWorker(errorMode: true));
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":40,"downloaded_size":12,"conn":[{"position":3,"downloaded_size":3,"size":10},{"position":13,"downloaded_size":3,"size":10},{"position":23,"downloaded_size":3,"size":10},{"position":33,"downloaded_size":3,"size":10}]}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":40,"downloaded_size":12,"conn":[{"position":3,"downloaded_size":3,"size":10},{"position":13,"downloaded_size":3,"size":10},{"position":23,"downloaded_size":3,"size":10},{"position":33,"downloaded_size":3,"size":10}]}');
      expect(t.progressValues, [
        0.025,
        0.05,
        0.075,
        0.1,
        0.125,
        0.15,
        0.175,
        0.2,
        0.225,
        0.25,
        0.275,
        0.3
      ]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TParallelWorker(), destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":40,"downloaded_size":12,"conn":[{"position":3,"downloaded_size":3,"size":10},{"position":13,"downloaded_size":3,"size":10},{"position":23,"downloaded_size":3,"size":10},{"position":33,"downloaded_size":3,"size":10}]}');
      expect(t.initialPoz, 12);
      expect(await t.readDestData(), TParallelWorker.s);
      expect(t.progressValues, [0.7, 0.8, 0.9, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });
}
