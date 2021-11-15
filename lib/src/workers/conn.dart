import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// A wrapper around [RetryClient]
class Conn {
  final RetryClient _client = RetryClient(http.Client());

  Future<http.Response> head(String url, {Map<String, String>? headers}) async {
    var resp = await _client.head(Uri.parse(url), headers: headers);
    _throwOnErrorHTTPCode(resp);
    return resp;
  }

  Future<http.StreamedResponse> get(String url) async {
    var req = http.Request('GET', Uri.parse(url));
    return _client.send(req);
  }

  void _throwOnErrorHTTPCode(http.Response resp) {
    if (resp.statusCode != 200) {
      throw Exception('Request failed with HTTP code ${resp.statusCode}');
    }
  }

  void close() {
    _client.close();
  }
}
