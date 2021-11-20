import 'package:buxing/buxing.dart';
import 'package:meta/meta.dart';

/// Base class for a parallel worker connection.
abstract class PWConnBase {
  final Uri url;
  ConnState _connState;
  Function()? onStateChange;

  ConnState get connState => _connState;

  PWConnBase(this.url, this._connState);

  Future<Stream<DataBody>> start() async {
    var stream = await startCore();
    return stream.map((bytes) => _createDataBody(bytes));
  }

  DataBody _createDataBody(List<int> bytes) {
    var body = DataBody(bytes, position: connState.start);
    var newConnState = ConnState(connState.start + bytes.length, connState.end);
    _connState = newConnState;
    onStateChange?.call();
    return body;
  }

  @protected
  Future<Stream<List<int>>> startCore();

  PWConnBase create(Uri url, ConnState connState);
  Future<void> close() async {}
}
