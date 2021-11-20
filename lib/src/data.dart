/// A chunk of data transferred from server.
class DataBody {
  /// The position the data should be written to. [null] if worker is not parallel.
  final int? position;

  /// The data bytes.
  final List<int> data;

  DataBody(this.data, {this.position});

  @override
  String toString() {
    return '${data.length} byte(s) at $position';
  }
}

/// Represents a range.
class DataRange {
  /// Start index of the range. Inclusive.
  final int start;

  /// End index of the range. Inclusive.
  final int end;

  DataRange(this.start, this.end) {
    if (end < start || start < 0 || end < 0) {
      throw Exception('Invalid range $start->$end');
    }
  }

  @override
  String toString() {
    return '$start~$end';
  }
}
