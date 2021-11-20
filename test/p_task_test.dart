import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_parallel_worker.dart';

void main() {
  test('Completed successfully with progress', () async {
    var t = TaskWrapper(worker: TParallelWorker());
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":40,"transferred":0,"conn":[{"start":0,"end":9},{"start":10,"end":19},{"start":20,"end":29},{"start":30,"end":39}]}');
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
          '{"url":"_url_","actual_url":"_url_","size":40,"transferred":16,"conn":[{"start":4,"end":9},{"start":14,"end":19},{"start":24,"end":29},{"start":34,"end":39}]}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":40,"transferred":16,"conn":[{"start":4,"end":9},{"start":14,"end":19},{"start":24,"end":29},{"start":34,"end":39}]}');
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
        0.3,
        0.325,
        0.35,
        0.375,
        0.4
      ]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TParallelWorker(), destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":40,"transferred":16,"conn":[{"start":4,"end":9},{"start":14,"end":19},{"start":24,"end":29},{"start":34,"end":39}]}');
      expect(t.initialPoz, 16);
      expect(await t.readDestData(), TParallelWorker.s);
      expect(t.progressValues, [
        0.425,
        0.45,
        0.475,
        0.5,
        0.525,
        0.55,
        0.575,
        0.6,
        0.625,
        0.65,
        0.675,
        0.7,
        0.725,
        0.75,
        0.775,
        0.8,
        0.825,
        0.85,
        0.875,
        0.9,
        0.925,
        0.95,
        0.975,
        1.0
      ]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });
}
