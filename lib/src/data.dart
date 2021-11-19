class DataHead {
  final Uri url;
  final Uri actualURL;
  final int size;

  DataHead(this.url, this.actualURL, this.size);
}

class DataBody {
  final int? position;
  final List<int> data;
  DataBody(this.data, {this.position});
}

class DataRange {
  final int position;
  final int size;
  DataRange(this.position, this.size) {
    if (size < 0) {
      throw Exception('Invalid range size $size');
    }
  }
}
