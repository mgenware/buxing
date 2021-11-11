import 'dart:convert';
import 'dart:ffi';

class State {
  final String url;
  final int size;
  final int downloadedSize = 0;

  State(this.url, this.size);

  String toJSON() {
    return jsonEncode({
      'url': url,
      'size': size,
      'downloaded_size': downloadedSize,
    });
  }
}
