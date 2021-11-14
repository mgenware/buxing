import 'dart:async';

import 'package:buxing/buxing.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

void throwOnErrorHTTPCode(http.Response resp) {
  if (resp.statusCode != 200) {
    throw Exception('Request failed with HTTP code ${resp.statusCode}');
  }
}

class Connection extends ConnectionBase {
  final RetryClient _client = RetryClient(http.Client());
  Uri? _uri;

  @override
  Future<DataHead> prepare(String url) async {
    logger?.log('conn: Sending head request...');
    var uri = Uri.parse(url);
    _uri = uri;
    var headResp = await _client.head(uri);
    _logResponse(headResp);
    throwOnErrorHTTPCode(headResp);

    // Fetch content size.
    var contentLength = headResp.headers['content-length'];
    var size = int.tryParse(contentLength ?? '') ?? -1;
    var dataHead = DataHead(url, url, size);
    return dataHead;
  }

  @override
  Future<Stream<List<int>>> start() async {
    logger?.log('conn: Sending data request...');
    var uri = _uri;
    if (uri == null) {
      throw Exception(
          'Unexpected null Uri. Make sure [prepare] is called before [start].');
    }
    var dataReq = http.Request('GET', uri);
    var dataResp = await _client.send(dataReq);
    return dataResp.stream;
  }

  @override
  void close() {
    _client.close();
  }

  void _logResponse(http.Response resp) {
    logger?.log('conn: head:status:\n${resp.statusCode}');
    logger?.log('conn: head:body:\n${resp.body}');
    logger?.log('conn: head:headers:\n${resp.headers}');
  }
}
