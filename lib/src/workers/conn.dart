import '../../buxing.dart';
import 'http_client_wrapper.dart';

/// The default [ConnBase] implementation.
class Conn extends ConnBase {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  Conn(StateHead head, ConnState connState, int bufferSize)
      : super(head, connState, bufferSize);

  @override
  Future<void> close() async {
    _conn.close();
  }

  @override
  Future<Stream<List<int>>> startCore() async {
    final resp = await _conn.get(head.url, range: initialState.range);
    return resp.stream;
  }
}
