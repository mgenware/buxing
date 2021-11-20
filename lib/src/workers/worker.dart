import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:buxing/buxing.dart';
import 'http_client_wrapper.dart';

class Worker extends WorkerBase {
  final HTTPClientWrapper _conn = HTTPClientWrapper();

  @override
  Future<StateHead> connect(Uri url) async {
    logger?.info('worker: Sending head request...');
    var headResp = await _conn.head(url);
    _logResponse(headResp);

    // Fetch content size.
    var contentLength = headResp.headers['content-length'];
    var size = int.tryParse(contentLength ?? '') ?? -1;
    return StateHead(url, url, size);
  }

  @override
  Future<Stream<DataBody>> start(State state) async {
    logger?.info('worker: Sending data request...');
    DataRange? range = state.transferred > 0
        ? DataRange(state.transferred, state.head.size - 1)
        : null;
    var resp = await _conn.get(state.head.url, range: range);
    return resp.stream.map((event) => DataBody(event));
  }

  @override
  Future<bool> canResume(StateHead head) {
    logger?.info('worker: Sending range check request...');
    return _conn.canResume(head.url);
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
