import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:buxing/buxing.dart';
import 'http_client_wrapper.dart';

class Worker extends WorkerBase {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  @override
  Future<DataHead> connect(Uri url) async {
    logger?.info('worker: Sending head request...');
    var headResp = await _conn.head(url);
    _logResponse(headResp);

    // Fetch content size.
    var contentLength = headResp.headers['content-length'];
    var size = int.tryParse(contentLength ?? '') ?? -1;
    var dataHead = DataHead(url, url, size);
    return dataHead;
  }

  @override
  Future<Stream<DataBody>> start(Uri url, State state) async {
    logger?.info('worker: Sending data request...');
    DataRange? range = state.transferred > 0
        ? DataRange(state.transferred, state.head.size)
        : null;
    var resp = await _conn.get(url, range: range);
    return resp.stream.map((event) => DataBody(event));
  }

  @override
  Future<bool> canResume(Uri url) {
    logger?.info('worker: Sending range check request...');
    return _conn.canResume(url);
  }

  @override
  Future<void> close() async {
    _conn.close();
  }

  void _logResponse(http.Response resp) {
    logger?.info('worker: head:status:\n${resp.statusCode}');
    logger?.info('worker: head:body:\n${resp.body}');
    logger?.info('worker: head:headers:\n${resp.headers}');
  }
}
