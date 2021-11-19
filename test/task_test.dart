import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';
import 't_worker.dart';

void main() {
  test('Completed', () async {
    var t = TaskWrapper();
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":10,"transferred":0}');
    expect(t.initialPoz, 0);
    expect(await t.readDestData(), TWorker.s);
    expect(t.progressValues, [0.2, 0.4, 0.6, 0.8, 1.0]);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Completed (unknown size)', () async {
    var t = TaskWrapper(worker: TWorker()..size = -1);
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":0}');
    expect(t.initialPoz, 0);
    expect(await t.readDestData(), TWorker.s);
    expect(t.progressValues, [-2.0, -4.0, -6.0, -8.0, -10.0]);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Completed (empty size)', () async {
    var t = TaskWrapper(worker: TWorker()..size = 0);
    await t.start();
    expect(t.initialState, '');
    expect(t.initialPoz, -1);
    expect(await t.readDestData(), '');
    expect(t.progressValues.isEmpty, true);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Completed (no range support)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..size = defSize
          ..canResumeValue = false);
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":10,"transferred":0}');
    expect(t.initialPoz, 0);
    expect(await t.readDestData(), TWorker.s);
    expect(t.progressValues, [0.2, 0.4, 0.6, 0.8, 1.0]);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Completed (no range support + unknown size)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..size = -1
          ..canResumeValue = false);
    await t.start();
    expect(t.initialState,
        '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":0}');
    expect(t.initialPoz, 0);
    expect(await t.readDestData(), TWorker.s);
    expect(t.progressValues, [-2.0, -4.0, -6.0, -8.0, -10.0]);
    expect(t.status, TaskStatus.completed);
    await t.close();
  });

  test('Head error', () async {
    var t = TaskWrapper(worker: TWorker()..headError = true);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(t.status, TaskStatus.error);
      expect(t.state, null);
      await t.close();
    }
  });

  test('Body error and restart (discard previous file)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..streamError = true
          ..size = defSize);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.progressValues, [0.2, 0.4, 0.6]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TWorker()..size = defSize);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":0}');
      expect(t.initialPoz, 0);
      expect(await t.readDestData(), TWorker.s);
      expect(t.progressValues, [0.2, 0.4, 0.6, 0.8, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });

  test('Body error and resume', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..streamError = true
          ..size = defSize);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.progressValues, [0.2, 0.4, 0.6]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TWorker()..size = defSize, destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.initialPoz, 6);
      expect(await t.readDestData(), TWorker.s);
      expect(t.progressValues, [0.7, 0.8, 0.9, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });

  test('Body error and resume (unknown size)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..streamError = true
          ..size = -1);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":6}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":6}');
      expect(t.progressValues, [-2.0, -4.0, -6.0]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(worker: TWorker()..size = -1, destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":0}');
      expect(t.initialPoz, 0);
      expect(await t.readDestData(), TWorker.s);
      expect(t.progressValues, [-2.0, -4.0, -6.0, -8.0, -10.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });

  test('Body error and resume (no range support)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..streamError = true
          ..size = defSize
          ..canResumeValue = false);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":6}');
      expect(t.progressValues, [0.2, 0.4, 0.6]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(
          worker: TWorker()
            ..size = defSize
            ..canResumeValue = false,
          destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":10,"transferred":0}');
      expect(t.initialPoz, 0);
      expect(await t.readDestData(), TWorker.s);
      expect(t.progressValues, [0.2, 0.4, 0.6, 0.8, 1.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });

  test('Body error and resume (no range support + unknown size)', () async {
    var t = TaskWrapper(
        worker: TWorker()
          ..streamError = true
          ..canResumeValue = false
          ..size = -1);
    try {
      await t.start();
      throw Exception();
    } catch (ex) {
      expect(await t.readStateString(),
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":6}');
      expect(t.state!.toJSON(),
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":6}');
      expect(t.progressValues, [-2.0, -4.0, -6.0]);
      expect(t.status, TaskStatus.error);
      await t.close();

      t = TaskWrapper(
          worker: TWorker()
            ..size = -1
            ..canResumeValue = false,
          destFile: t.destFile);
      await t.start();
      expect(t.initialState,
          '{"url":"_url_","actual_url":"_url_","size":-1,"transferred":0}');
      expect(t.initialPoz, 0);
      expect(await t.readDestData(), TWorker.s);
      expect(t.progressValues, [-2.0, -4.0, -6.0, -8.0, -10.0]);
      expect(t.status, TaskStatus.completed);
      await t.close();
    }
  });
}
