import 'package:buxing/src/data.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

const rangeStatus = 206;

/// A wrapper around [RetryClient]
class HTTPClientWrapper {
  final RetryClient _client = RetryClient(http.Client());

  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    var resp = await _client.head(url, headers: headers);
    _throwOnErrorHTTPCode(resp.statusCode);
    return resp;
  }

  Future<http.StreamedResponse> get(Uri url, {DataRange? range}) async {
    var req = http.Request('GET', url);
    if (range != null) {
      req.headers['Range'] = 'bytes=${range.start}-${range.end}';
    }
    var resp = await _client.send(req);
    _throwOnErrorHTTPCode(resp.statusCode);
    if (range != null && resp.statusCode != rangeStatus) {
      throw Exception(
          'Got invalid status ${resp.statusCode} from range request');
    }
    return resp;
  }

  Future<bool> canResume(Uri url) async {
    var resp = await head(url, headers: {'Range': 'bytes=0-'});
    return resp.statusCode == rangeStatus;
  }

  void _throwOnErrorHTTPCode(int code) {
    if (code < 200 || code > 299) {
      throw Exception('Request failed with HTTP code $code');
    }
  }

  void close() {
    _client.close();
  }
}
