import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:buxing/buxing.dart';
import 'package:buffered_list_stream/buffered_list_stream.dart';
import 'http_client_wrapper.dart';

/// The default worker implementation.
class Worker extends WorkerBase {
  /// Internal buffer size.
  final int bufferSize;

  final HTTPClientWrapper _conn = HTTPClientWrapper();

  Worker({this.bufferSize = 200000});

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
    var bufferedStream = bufferedListStream(resp.stream, bufferSize);
    return bufferedStream.map((s) => DataBody(s));
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
