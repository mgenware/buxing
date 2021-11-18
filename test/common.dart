import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

var uuid = Uuid();

var defURL = Uri.parse('https://www.mgenware.com');
const defSize = 10;

String newFile() {
  return p.join(Directory.systemTemp.path, uuid.v4());
}
