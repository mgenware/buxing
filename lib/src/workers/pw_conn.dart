import 'package:buxing/src/workers/http_client_wrapper.dart';
import 'package:buxing/src/workers/pw_conn_base.dart';

class PWConn extends PWConnBase {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  PWConn(Uri url, int position, int size) : super(url, position, size);

  void close() {
    _conn.close();
  }

  @override
  Future<Stream<List<int>>> startCore() async {
    var resp = await _conn.get(url);
    return resp.stream;
  }

  @override
  PWConn create(Uri url, int position, int size) {
    return PWConn(url, position, size);
  }
}
