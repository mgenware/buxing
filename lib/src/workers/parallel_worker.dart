import 'package:buxing/buxing.dart';
import 'package:buxing/src/workers/pw_conn.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';

const defConnNumber = 5;

class ParallelWorker extends Worker {
  final List<PWConnBase> _conns = [];
  late final int concurrency;

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
  Future<Stream<DataBody>> start(Uri url, State state) async {
    logger?.info('p_worker: Sending data request...');
    logger?.info('p_worker: Got ${state.conns.length} state conns...');
    for (var i = 0; i < state.conns.length; i++) {
      var stateConn = state.conns[i];
      var pwConn = createPWConn(url, stateConn);
      pwConn.onTransfer = () {
        stateConn.transferred = pwConn.downloaded;
        stateConn.position = pwConn.position;
      };
      _conns.add(pwConn);
    }
    var streams = await Future.wait(_conns.map((e) => e.start()));
    return StreamGroup.merge(streams);
  }

  List<ConnState> _createConnStates(State state) {
    var connSize = (state.head.size / concurrency).round();
    ConnState? prevState;
    ConnState? curState;
    List<ConnState> conns = [];
    for (var i = 0; i < concurrency; i++) {
      curState = ConnState(
          prevState != null ? prevState.position + prevState.size : 0,
          0,
          connSize);
      conns.add(curState);
      prevState = curState;
    }
    // Make sure last state covers all the remaining part.
    curState!.size = state.head.size - curState.position;
    return conns;
  }

  @protected
  PWConnBase createPWConn(Uri url, ConnState connState) {
    return PWConn(url, connState.position, connState.size);
  }

  @override
  Future<void> close() async {
    await Future.wait(_conns.map((e) => e.close()));
  }
}
