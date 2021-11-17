import 'package:meta/meta.dart';

abstract class PWConn {
  final Uri url;
  final int position;

  // Size can be halved if the connection spawns another connection.
  int _size;

  @protected
  int _downloaded = 0;

  int get size => _size;

  int get downloaded => _downloaded;

  PWConn(this.url, this.position, int size) : _size = size;

  Future<Stream<List<int>>> start();

  PWConn create(Uri url, int position, int size);
  PWConn spawn() {
    var leftSize = (size / 2).round();
    var rightSize = size - leftSize;
    var newConn = create(url, position + leftSize, rightSize);
    _size = leftSize;
    return newConn;
  }
}
