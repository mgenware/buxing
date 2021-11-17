import 'package:buxing/buxing.dart';
import 'package:buxing/src/workers/http_pw_conn.dart';
import 'package:meta/meta.dart';

const defConnNumber = 5;

class ParallelWorker extends Worker {
  List<PWConn> _conns = [];

  @override
  Future<State> prepare(State state) async {
    if (state.conns.isEmpty) {
      var connStates = _createConnStates(state);
      state.conns = connStates;
    }
    return state;
  }

  @override
  Future<Stream<DataBody>> start(Uri url, State state) async {
    logger?.log('conn: Sending data request...');
    _conns = state.conns.map((e) => createPWConn(url, e)).toList();
  }

  List<ConnState> _createConnStates(State state) {
    var connSize = (state.head.size / defConnNumber).round();
    ConnState? prevState;
    ConnState? curState;
    List<ConnState> conns = [];
    for (var i = 0; i < defConnNumber; i++) {
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
  PWConn createPWConn(Uri url, ConnState connState) {
    return HTTPPWConn(url, connState.position, connState.size);
  }
}
