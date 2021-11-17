import 'package:buxing/src/workers/http_client_wrapper.dart';
import 'package:buxing/src/workers/pw_conn.dart';

class HTTPPWConn extends PWConn {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  HTTPPWConn(Uri url, int position, int size) : super(url, position, size);

  void close() {
    _conn.close();
  }

  @override
  Future<Stream<List<int>>> start() async {
    var resp = await _conn.get(url);
    return resp.stream;
  }

  @override
  PWConn create(Uri url, int position, int size) {
    return HTTPPWConn(url, position, size);
  }
}
