import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// A wrapper around [RetryClient]
class HTTPClientWrapper {
  final RetryClient _client = RetryClient(http.Client());

  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    var resp = await _client.head(url, headers: headers);
    _throwOnErrorHTTPCode(resp);
    return resp;
  }

  Future<http.StreamedResponse> get(Uri url) async {
    var req = http.Request('GET', url);
    return _client.send(req);
  }

  Future<bool> canResume(Uri url) async {
    var resp = await head(url, headers: {'Range': 'bytes=0-'});
    return resp.statusCode == 206;
  }

  void _throwOnErrorHTTPCode(http.Response resp) {
    var code = resp.statusCode;
    if (code < 200 || code > 299) {
      throw Exception('Request failed with HTTP code ${resp.statusCode}');
    }
  }

  void close() {
    _client.close();
  }
}
