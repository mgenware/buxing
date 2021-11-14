import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

var uuid = Uuid();

const defURL = '_URL_';
const defSize = 10;

String newFile() {
  return p.join(Directory.systemTemp.path, uuid.v4());
}
