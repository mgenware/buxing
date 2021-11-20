import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_parallel_worker.dart';

void main() {
  test('Completed successfully with progress', () async {
    var t = TaskWrapper(worker: TParallelWorker());
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":43,"transferred":0,"conn":[{"start":0,"end":10},{"start":11,"end":21},{"start":22,"end":32},{"start":33,"end":42}]}');
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
          '{"url":"_url_","actual_url":"_url_","size":43,"transferred":16,"conn":[{"start":4,"end":10},{"start":15,"end":21},{"start":26,"end":32},{"start":37,"end":42}]}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":43,"transferred":16,"conn":[{"start":4,"end":10},{"start":15,"end":21},{"start":26,"end":32},{"start":37,"end":42}]}');
      expect(t.progressValues, [
        0.02,
        0.05,
        0.07,
        0.09,
        0.12,
        0.14,
        0.16,
        0.19,
        0.21,
        0.23,
        0.26,
        0.28,
        0.3,
        0.33,
        0.35,
        0.37
      ]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TParallelWorker(), destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":43,"transferred":16,"conn":[{"start":4,"end":10},{"start":15,"end":21},{"start":26,"end":32},{"start":37,"end":42}]}');
      expect(t.initialPoz, 16);
      expect(await t.readDestData(), TParallelWorker.s);
      expect(t.progressValues, [
        0.4,
        0.42,
        0.44,
        0.47,
        0.49,
        0.51,
        0.53,
        0.56,
        0.58,
        0.6,
        0.63,
        0.65,
        0.67,
        0.7,
        0.72,
        0.74,
        0.77,
        0.79,
        0.81,
        0.84,
        0.86,
        0.88,
        0.91,
        0.93,
        0.95,
        0.98,
        1.0,
      ]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });
}
