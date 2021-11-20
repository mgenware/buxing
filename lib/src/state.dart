import 'dart:convert';

import 'package:buxing/src/data.dart';

const urlKey = 'url';
const actualUrlKey = 'actual_url';
const sizeKey = 'size';
const transferredKey = 'transferred';
const parallelKey = 'parallel';
const startKey = 'start';
const endKey = 'end';
const connKey = 'conn';

class ConnState {
  final int start;
  final int end;

  ConnState(this.start, this.end);

  ConnState.fromJson(Map<String, dynamic> json)
      : start = json[startKey] as int,
        end = json[endKey] as int;

  // ignore: implicit_dynamic_map_literal
  Map<String, dynamic> toJson() => {
        startKey: start,
        endKey: end,
      };
}

class State {
  final DataHead head;
  int transferred = 0;
  bool parallel = false;
  List<ConnState> conns = [];

  State(this.head);

  String toJSON() {
    // ignore: implicit_dynamic_map_literal
    Map<String, dynamic> dict = {
      urlKey: head.url.toString(),
      actualUrlKey: head.actualURL.toString(),
      sizeKey: head.size,
      transferredKey: transferred,
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
    state.transferred = map[transferredKey] as int;
    state.parallel = (map[parallelKey] ?? false) as bool;
    // ignore: implicit_dynamic_list_literal
    for (var dict in (map[connKey] ?? []) as List<dynamic>) {
      state.conns.add(ConnState.fromJson(dict as Map<String, dynamic>));
    }
    return state;
  }
}
