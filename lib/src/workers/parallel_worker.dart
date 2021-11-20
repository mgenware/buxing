import 'dart:math';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/workers/conn.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';

const defConnNumber = 5;

class ParallelWorker extends Worker {
  final Map<String, ConnBase> _conns = {};
  late final int concurrency;
  int _idCounter = 0;

  ParallelWorker({int concurrency = -1}) {
    this.concurrency = concurrency <= 0 ? defConnNumber : concurrency;
  }

  @override
  Future<State> prepare(State state) async {
    logger?.info('p_worker: Sending head request...');
    if (state.conns.isEmpty) {
      var connStates = _createConnStates(state);
      logger?.info('p_worker: Created ${connStates.length} state conns...');
      state.conns = connStates;
    }
    return state;
  }

  @override
  Future<Stream<DataBody>> start(State state) async {
    logger?.info('p_worker: Sending data request...');
    logger?.info('p_worker: Got ${state.conns.length} state conns...');

    for (var connState in state.conns.values) {
      var conn = spawnConn(state.head, connState);
      conn.onStateChange = (s) async {
        var id = conn.id;
        if (s == null) {
          await conn.close();
          state.conns.remove(id);
          _conns.remove(id);
        } else {
          state.conns[id] = s;
        }
      };
      _conns[conn.id] = conn;
    }
    var streams = await Future.wait(_conns.values.map((e) => e.start()));
    return StreamGroup.merge(streams);
  }

  Map<String, ConnState> _createConnStates(State state) {
    var avgSize = (state.head.size / concurrency).round();
    ConnState? prevState;
    ConnState? curState;
    Map<String, ConnState> conns = {};
    for (var i = 0; i < concurrency; i++) {
      curState = ConnState(
          nextConnID(),
          prevState != null ? prevState.end + 1 : 0,
          prevState != null ? prevState.end + avgSize : avgSize - 1);
      conns[curState.id] = curState;
      prevState = curState;
    }
    // Make sure last state covers the whole range.
    conns[curState!.id] = ConnState(curState.id,
        min(curState.start, state.head.size - 1), state.head.size - 1);
    return conns;
  }

  @protected
  ConnBase spawnConn(StateHead head, ConnState connState) {
    return Conn(head, connState);
  }

  @override
  Future<void> close() async {
    await Future.wait(_conns.values.map((e) => e.close()));
  }

  @protected
  String nextConnID() {
    return '${++_idCounter}';
  }
}
