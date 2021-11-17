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
