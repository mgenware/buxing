import 'dart:convert';
import 'dart:io';
import 'package:buxing/buxing.dart';
import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

var uuid = Uuid();

var defURL = Uri.parse('https://www.mgenware.com');
const defSize = 10;

var realURL = Uri.parse('https://golang.org/dl/go1.17.3.src.tar.gz');
const realURLChecksum =
    '705c64251e5b25d5d55ede1039c6aa22bea40a7a931d14c370339853643c3df0';

String newFile() {
  return p.join(Directory.systemTemp.path, uuid.v4());
}

Future<void> verifyRealFile(String file) async {
  var hash = sha256.convert(await File(file).readAsBytes()).toString();
  if (hash != realURLChecksum) {
    throw Exception('Hash mismatched on downloaded file');
  }
}

extension Test on Task {
  Future<String> readDestData() async {
    var bytes = await File(destFile).readAsBytes();
    return hex.encode(bytes);
  }

  Future<String> readDestString() async {
    return File(destFile).readAsString();
  }

  Future<String> readStateString() async {
    return File(stateFile!).readAsString();
  }

  Future<String> readLocalStateString() async {
    return jsonEncode(state);
  }
}
