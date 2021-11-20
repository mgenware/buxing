class DataBody {
  final int? position;
  final List<int> data;
  DataBody(this.data, {this.position});

  @override
  String toString() {
    return '${data.length} byte(s) at $position';
  }
}

class DataRange {
  final int start;
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
