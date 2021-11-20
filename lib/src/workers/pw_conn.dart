import 'package:buxing/buxing.dart';
import 'package:buxing/src/workers/http_client_wrapper.dart';

class PWConn extends PWConnBase {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  PWConn(Uri url, ConnState connState) : super(url, connState);

  @override
  Future<void> close() async {
    _conn.close();
  }

  @override
  Future<Stream<List<int>>> startCore() async {
    var resp = await _conn.get(url,
        range: DataRange(connState.start, connState.end - connState.start + 1));
    return resp.stream;
  }

  @override
  PWConn create(Uri url, ConnState connState) {
    return PWConn(url, connState);
  }
}
