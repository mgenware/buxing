import 'package:buxing/src/data.dart';
import 'package:meta/meta.dart';

/// Base class for a parallel worker connection.
abstract class PWConnBase {
  final Uri url;
  int _position;

  // Size can be halved if the connection spawns another connection.
  int _size;

  @protected
  int _downloaded = 0;

  int get size => _size;
  int get position => _position;
  int get downloaded => _downloaded;

  Function()? onTransfer;

  PWConnBase(this.url, int position, int size)
      : _size = size,
        _position = position;

  Future<Stream<DataBody>> start() async {
    var stream = await startCore();
    return stream.map((bytes) => _createDataBody(bytes));
  }

  DataBody _createDataBody(List<int> bytes) {
    var body = DataBody(bytes, position: _position);
    _position += bytes.length;
    _downloaded += bytes.length;
    onTransfer?.call();
    return body;
  }

  @protected
  Future<Stream<List<int>>> startCore();

  PWConnBase create(Uri url, int position, int size);
  PWConnBase spawn() {
    var leftSize = (size / 2).round();
    var rightSize = size - leftSize;
    var newConn = create(url, _position + leftSize, rightSize);
    _size = leftSize;
    return newConn;
  }

  Future<void> close() async {}
}
