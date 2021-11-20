import 'package:buxing/buxing.dart';
import 'package:meta/meta.dart';
import 'package:buffered_list_stream/buffered_list_stream.dart';

/// Base class for a parallel worker connection.
abstract class ConnBase {
  /// Gets the state header.
  final StateHead head;

  /// Gets the initial connection stated passed in constructor.
  final ConnState initialState;

  /// Gets the buffer size of this connection.
  final int bufferSize;

  /// Fires when connection state updates.
  Function(ConnState?)? onStateChange;

  int _transferred = 0;

  /// Returns the identifier of this connection.
  String get id => initialState.id;

  /// Returns the number of bytes transferred.
  int get transferred => _transferred;

  ConnBase(this.head, this.initialState, this.bufferSize);

  /// Starts transmission from server.
  Future<Stream<DataBody>> start() async {
    var bufferedStream = bufferedListStream(await startCore(), bufferSize);
    return bufferedStream.map((bytes) {
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
