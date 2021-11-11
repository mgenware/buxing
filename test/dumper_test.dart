import 'dart:convert';

import 'package:convert/convert.dart';
import 'dart:io';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/state.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

var uuid = Uuid();
const defURL = '_URL_';
const defSize = 10;

String newFile() {
  return p.join(Directory.systemTemp.path, uuid.v4());
}

Future<Dumper> newDumper() async {
  var file = newFile();
  var state = State(defURL, defSize);
  var d = await Dumper.create(file, state);
  await d.prepare();
  // Set position to start of the file.
  await d.seek(0);
  return d;
}

extension Test on Dumper {
  Future writeString(String s) async {
    await writeData(ascii.encode(s));
  }

  Future<String> readDataString() async {
    var bytes = await File(dataPath).readAsBytes();
    return hex.encode(bytes);
  }

  Future<int> readFileSize() async {
    return await File(dataPath).length();
  }
}

void main() {
  test('Create dumper', () async {
    var d = await newDumper();
    expect(await d.readFileSize(), defSize);
    expect(d.dataPath, d.path + '.bxdown');
    expect(d.statePath, d.path + '.bxdownstate');
    await d.close();
  });

  test('write', () async {
    var d = await newDumper();
    await d.writeString('a');
    expect(await d.readDataString(), '61000000000000000000');

    await d.writeString('b');
    expect(await d.readDataString(), '61620000000000000000');

    await d.seek(6);
    await d.writeString('c');
    expect(await d.readDataString(), '61620000000063000000');

    await d.close();
  });
}
