class DataHead {
  final String url;
  final String actualURL;
  final int size;

  DataHead(this.url, this.actualURL, this.size);
}

class DataBody {
  final int? index;
  final List<int> data;
  DataBody(this.data, {this.index});
}
