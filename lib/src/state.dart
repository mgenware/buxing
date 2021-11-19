import 'dart:convert';

import 'package:buxing/src/data.dart';

const urlKey = 'url';
const actualUrlKey = 'actual_url';
const sizeKey = 'size';
const downloadedSizeKey = 'downloaded_size';
const parallelKey = 'parallel';
const positionKey = 'position';
const connKey = 'conn';

class ConnState {
  int position;
  int downloadedSize;
  int size;

  ConnState(this.position, this.downloadedSize, this.size);

  ConnState.fromJson(Map<String, dynamic> json)
      : position = json[positionKey] as int,
        downloadedSize = json[downloadedSizeKey] as int,
        size = json[sizeKey] as int;

  // ignore: implicit_dynamic_map_literal
  Map<String, dynamic> toJson() => {
        positionKey: position,
        downloadedSizeKey: downloadedSize,
        sizeKey: size,
      };
}

class State {
  final DataHead head;
  int downloadedSize = 0;
  bool parallel = false;
  List<ConnState> conns = [];

  State(this.head);

  String toJSON() {
    // ignore: implicit_dynamic_map_literal
    Map<String, dynamic> dict = {
      urlKey: head.url.toString(),
      actualUrlKey: head.actualURL.toString(),
      sizeKey: head.size,
      downloadedSizeKey: downloadedSize,
    };
    if (parallel) {
      dict[parallelKey] = true;
    }
    if (conns.isNotEmpty) {
      dict[connKey] = conns;
    }
    return jsonEncode(dict);
  }

  static State fromJSON(String json) {
    // Any errors thrown here are expected and should be handled
    // as data corruption.
    var map = jsonDecode(json) as Map<String, dynamic>;
    var state = State(DataHead(Uri.parse(map[urlKey] as String),
        Uri.parse(map[actualUrlKey] as String), map[sizeKey] as int));
    state.downloadedSize = map[downloadedSizeKey] as int;
    state.parallel = (map[parallelKey] ?? false) as bool;
    // ignore: implicit_dynamic_list_literal
    for (var dict in (map[connKey] ?? []) as List<dynamic>) {
      state.conns.add(ConnState.fromJson(dict as Map<String, dynamic>));
    }
    return state;
  }
}
