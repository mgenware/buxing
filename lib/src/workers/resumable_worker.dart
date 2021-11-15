import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:buxing/buxing.dart';
import 'conn.dart';

class ResumableWorker extends WorkerBase {
  final Conn _conn = Conn();
  String? _url;

  @override
  Future<DataHead> prepare(String url) async {
    logger?.log('conn: Sending head request...');
    _url = url;
    var headResp = await _conn.head(url);
    _logResponse(headResp);

    // Fetch content size.
    var contentLength = headResp.headers['content-length'];
    var size = int.tryParse(contentLength ?? '') ?? -1;
    var dataHead = DataHead(url, url, size);
    return dataHead;
  }

  @override
  Future<Stream<List<int>>> start() async {
    logger?.log('conn: Sending data request...');
    var resp = await _conn.get(_mustGetURL());
    return resp.stream;
  }

  @override
  Future<bool> canResume() async {
    logger?.log('conn: Sending range check request...');
    var resp = await _conn.head(_mustGetURL(), headers: {'Range': 'bytes=0-'});
    return resp.statusCode == 206;
  }

  @override
  void close() {
    _conn.close();
  }

  void _logResponse(http.Response resp) {
    logger?.log('conn: head:status:\n${resp.statusCode}');
    logger?.log('conn: head:body:\n${resp.body}');
    logger?.log('conn: head:headers:\n${resp.headers}');
  }

  String _mustGetURL() {
    var url = _url;
    if (url == null) {
      throw Exception(
          'Unexpected null Uri. Make sure [prepare] is called before [start].');
    }
    return url;
  }
}
