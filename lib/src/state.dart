import 'dart:convert';

import 'package:buxing/src/data.dart';

const urlKey = 'url';
const actualUrlKey = 'actual_url';
const sizeKey = 'size';
const downloadedSizeKey = 'downloaded_size';

class State {
  final DataHead head;
  int downloadedSize = 0;

  State(this.head);

  String toJSON() {
    return jsonEncode({
      urlKey: head.url,
      actualUrlKey: head.actualURL,
      sizeKey: head.size,
      downloadedSizeKey: downloadedSize,
    });
  }

  static State fromJSON(String json) {
    // Any errors thrown here are expected and should be handled
    // as data corruption.
    var map = jsonDecode(json) as Map<String, dynamic>;
    var state = State(DataHead(map[urlKey] as String,
        map[actualUrlKey] as String, map[sizeKey] as int));
    state.downloadedSize = map[downloadedSizeKey] as int;
    return state;
  }
}
