import 'dart:convert';

import 'data.dart';

// Constants used in JSON serialization / deserialization.
const urlKey = 'url';
const originalURLKey = 'original_url';
const sizeKey = 'size';
const transferredKey = 'transferred';
const parallelKey = 'parallel';
const startKey = 'start';
const endKey = 'end';
const connKey = 'conn';
const idKey = 'id';

/// Contains information about an ongoing connection in a parallel worker.
class ConnState {
  /// The identifier of this connection.
  final String id;

  /// The data range to be transferred.
  final DataRange range;

  /// Shortcut for [range.start].
  int get start => range.start;

  /// Shortcut for [range.end].
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

/// Core information about a task such as URL, file size etc.
class StateHead {
  /// Original URL passed in constructor.
  final Uri originalURL;

  /// Resolved URL.
  final Uri url;

  /// Server file size, can be -1 if unknown.
  final int size;

  StateHead(this.originalURL, this.url, this.size);

  @override
  String toString() {
    return '$size [$url]';
  }
}

/// Represents a download task that will be persisted to disk.
/// A state is deleted when the task is completed.
class State {
  /// Core information about a task such as URL, file size etc.
  final StateHead head;

  /// Number of bytes transferred.
  int transferred = 0;

  /// Indicates if a parallel worker is used.
  bool parallel = false;

  /// Connection state, only applicable to a parallel worker.
  Map<String, ConnState> conns = {};

  State(this.head);

  /// Serializes a state to a JSON string.
  String toJSON() {
    // ignore: implicit_dynamic_map_literal
    final Map<String, dynamic> dict = {
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

  /// Deserializes a state from a JSON string.
  static State fromJSON(String json) {
    // Any errors thrown here are expected and should be handled
    // as data corruption.
    final map = jsonDecode(json) as Map<String, dynamic>;
    final state = State(StateHead(Uri.parse(map[originalURLKey] as String),
        Uri.parse(map[urlKey] as String), map[sizeKey] as int));
    state.transferred = map[transferredKey] as int;
    state.parallel = (map[parallelKey] ?? false) as bool;
    // ignore: implicit_dynamic_map_literal
    final connsMap = map[connKey] as Map<String, dynamic>?;
    if (connsMap != null) {
      for (var connDict in connsMap.values) {
        final connState = ConnState.fromJson(connDict as Map<String, dynamic>);
        state.conns[connState.id] = connState;
      }
    }
    return state;
  }
}
