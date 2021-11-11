import 'package:http/http.dart' as http;

class Stream {
  final String url;
  late final http.Client? _client;

  Stream(this.url);

  Future<http.StreamedResponse> start() async {
    final url = Uri.parse(this.url);
    final client = http.Client();
    final request = http.Request('GET', url);
    final response = await client.send(request);
    _client = client;
    return response;
  }

  void close() {
    _client?.close();
  }
}
