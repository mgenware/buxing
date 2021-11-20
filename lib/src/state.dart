import 'dart:convert';

import 'package:buxing/src/data.dart';

const urlKey = 'url';
const originalURLKey = 'original_url';
const sizeKey = 'size';
const transferredKey = 'transferred';
const parallelKey = 'parallel';
const startKey = 'start';
const endKey = 'end';
const connKey = 'conn';
const idKey = 'id';

class ConnState {
  final String id;
  final DataRange range;
  int get start => range.start;
  int get end => range.end;

  ConnState(this.id, int start, int end) : range = DataRange(start, end);

  ConnState.fromJson(Map<String, dynamic> json)
      : id = json[idKey] as String,
        range = DataRange(json[startKey] as int, json[endKey] as int);

  // ignore: implicit_dynamic_map_literal
  Map<String, dynamic> toJson() => {
        startKey: range.start,
        endKey: range.end,
        idKey: id,
      };
}

class StateHead {
  final Uri originalURL;
  final Uri url;
  final int size;

  StateHead(this.originalURL, this.url, this.size);

  @override
  String toString() {
    return '$size [$url]';
  }
}

class State {
  final StateHead head;
  int transferred = 0;
  bool parallel = false;
  Map<String, ConnState> conns = {};

  State(this.head);

  String toJSON() {
    // ignore: implicit_dynamic_map_literal
    Map<String, dynamic> dict = {
      urlKey: head.url.toString(),
      originalURLKey: head.originalURL.toString(),
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
    var state = State(StateHead(Uri.parse(map[originalURLKey] as String),
        Uri.parse(map[urlKey] as String), map[sizeKey] as int));
    state.transferred = map[transferredKey] as int;
    state.parallel = (map[parallelKey] ?? false) as bool;
    // ignore: implicit_dynamic_map_literal
    var connsMap = (map[connKey] ?? {}) as Map<String, ConnState>;
    for (var connDict in connsMap.values) {
      var connState = ConnState.fromJson(connDict as Map<String, dynamic>);
      state.conns[connState.id] = connState;
    }
    return state;
  }
}
