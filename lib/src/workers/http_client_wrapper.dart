import '../data.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Valid HTTP status code for a RANGE request.
const rangeStatus = 206;

/// A wrapper around [RetryClient].
class HTTPClientWrapper {
  final RetryClient _client = RetryClient(http.Client());

  /// Sends a HEAD request.
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    final resp = await _client.head(url, headers: headers);
    _throwOnErrorHTTPCode(resp.statusCode);
    return resp;
  }

  /// Sends a GET request.
  Future<http.StreamedResponse> get(Uri url, {DataRange? range}) async {
    final req = http.Request('GET', url);
    if (range != null) {
      req.headers['Range'] = 'bytes=${range.start}-${range.end}';
    }
    final resp = await _client.send(req);
    _throwOnErrorHTTPCode(resp.statusCode);
    if (range != null && resp.statusCode != rangeStatus) {
      throw Exception(
          'Got invalid status ${resp.statusCode} from range request');
    }
    return resp;
  }

  /// Sends a HEAD request with a RANGE header.
  Future<bool> canResume(Uri url) async {
    final resp = await head(url, headers: {'Range': 'bytes=0-'});
    return resp.statusCode == rangeStatus;
  }

  void _throwOnErrorHTTPCode(int code) {
    if (code < 200 || code > 299) {
      throw Exception('Request failed with HTTP code $code');
    }
  }

  /// Closes the internal HTTP client.
  void close() {
    _client.close();
  }
}
