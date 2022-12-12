import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'helper/common.dart';
import 'helper/t_parallel_worker.dart';

void main() {
  test('Completed successfully with progress', () async {
    var t = TaskWrapper(worker: TParallelWorker());
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","original_url":"_url_","size":43,"transferred":0,"conn":{"1":{"start":0,"end":10,"id":"1"},"2":{"start":11,"end":21,"id":"2"},"3":{"start":22,"end":32,"id":"3"},"4":{"start":33,"end":42,"id":"4"}}}');
    expect(await t.readDestData(), TParallelWorker.s);
    expect(t.progressValues.every((e) => e > 0 && e <= 100), true);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Body error and resume (full pause)', () async {
    var t = TaskWrapper(worker: TParallelWorker(fullPause: true));
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":16,"conn":{"1":{"start":4,"end":10,"id":"1"},"2":{"start":15,"end":21,"id":"2"},"3":{"start":26,"end":32,"id":"3"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":16,"conn":{"1":{"start":4,"end":10,"id":"1"},"2":{"start":15,"end":21,"id":"2"},"3":{"start":26,"end":32,"id":"3"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.progressValues, [0.09, 0.19, 0.28, 0.37]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TParallelWorker(), destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":16,"conn":{"1":{"start":4,"end":10,"id":"1"},"2":{"start":15,"end":21,"id":"2"},"3":{"start":26,"end":32,"id":"3"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.initialPoz, 16);
      expect(await t.readDestData(), TParallelWorker.s);
      expect(t.progressValues, [0.51, 0.65, 0.67, 0.7, 0.84, 0.98, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });

  test('Body error and resume (partial pause)', () async {
    var t = TaskWrapper(worker: TParallelWorker(partialPause: true));
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":30,"conn":{"2":{"start":15,"end":21,"id":"2"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":30,"conn":{"2":{"start":15,"end":21,"id":"2"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.progressValues, [0.09, 0.23, 0.37, 0.49, 0.6, 0.7]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TParallelWorker(), destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","original_url":"_url_","size":43,"transferred":30,"conn":{"2":{"start":15,"end":21,"id":"2"},"4":{"start":37,"end":42,"id":"4"}}}');
      expect(t.initialPoz, 30);
      expect(await t.readDestData(), TParallelWorker.s);
      expect(t.progressValues, [0.84, 0.98, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });
}
