import 'package:buxing/buxing.dart';
import 'package:meta/meta.dart';

/// Base class for a parallel worker connection.
abstract class ConnBase {
  final StateHead head;
  final ConnState initialState;
  int _transferred = 0;
  Function(ConnState?)? onStateChange;

  String get id => initialState.id;
  int get transferred => _transferred;

  ConnBase(this.head, this.initialState);

  Future<Stream<DataBody>> start() async {
    var stream = await startCore();
    return stream.map((bytes) {
      var body = _createDataBody(bytes);
      var newState = initialState.start + _transferred > initialState.end
          ? null
          : ConnState(initialState.id, initialState.start + _transferred,
              initialState.end);
      onStateChange?.call(newState);
      return body;
    });
  }

  DataBody _createDataBody(List<int> bytes) {
    var body = DataBody(bytes, position: initialState.start + _transferred);
    _transferred += bytes.length;
    return body;
  }

  @protected
  Future<Stream<List<int>>> startCore();
  Future<void> close() async {}
}
