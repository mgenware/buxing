import 'dart:async';

import 'package:buxing/src/connection_base.dart';
import 'package:buxing/src/data.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

void throwOnErrorHTTPCode(http.Response resp) {
  if (resp.statusCode != 200) {
    throw Exception('Request failed with HTTP code ${resp.statusCode}');
  }
}

class Connection extends ConnectionBase {
  final RetryClient _client = RetryClient(http.Client());

  @override
  Future<Stream<List<int>>> start(String url) async {
    logger?.log('Sending head request...');
    var uri = Uri.parse(url);
    var headResp = await _client.head(uri);
    _logResponse(headResp);
    throwOnErrorHTTPCode(headResp);

    // Fetch content size.
    var contentLength = headResp.headers['content-length'];
    var size = int.tryParse(contentLength ?? '') ?? -1;
    onHeaderReceived?.call(DataHead(url, url, size));

    logger?.log('Sending data request...');
    var dataReq = http.Request('GET', uri);
    var dataResp = await _client.send(dataReq);
    return dataResp.stream;
  }

  void close() {
    _client.close();
  }

  void _logResponse(http.Response resp) {
    logger?.log('conn.start:status:\n${resp.statusCode}');
    logger?.log('conn.start:body:\n${resp.body}');
    logger?.log('conn.start:headers:\n${resp.headers}');
  }
}
