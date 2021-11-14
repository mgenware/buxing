import 'dart:convert';

import 'package:convert/convert.dart';

import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'common.dart';

Future<Dumper> newDumper() async {
  var file = newFile();
  var head = DataHead(defURL, defURL, defSize);
  var d = await Dumper.create(file, head);
  // Set position to start of the file.
  await d.seek(0);
  return d;
}

extension Test on Dumper {
  Future writeString(String s) async {
    await writeData(ascii.encode(s));
  }

  Future<String> readDataString() async {
    var bytes = await dataFile.readAsBytes();
    return hex.encode(bytes);
  }

  Future<String> readStateString() async {
    return stateFile.readAsString();
  }

  Future<State> readState() async {
    return State.fromJSON(await readStateString());
  }

  String currentStateJSON() {
    return currentState.toJSON();
  }
}

void main() {
  test('Create', () async {
    var d = await newDumper();
    expect(d.dataFile.path, d.path + '.bxdown');
    expect(await d.readDataString(), '00000000000000000000');
    expect(d.stateFile.path, d.path + '.bxdownstate');
    expect(await d.readStateString(), d.currentStateJSON());
    await d.close();
  });

  test('Write and seek', () async {
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

  test('Create and erase', () async {
    // Create a dumper and set contents.
    var d = await newDumper();
    await d.writeData([1, 2, 3, 4]);
    await d.close();

    // Create a new dumper with the same name.
    const newSize = 7;
    const newURL = '_new_url_';
    var head = DataHead(newURL, newURL, newSize);
    d = await Dumper.create(d.path, head);
    expect(await d.readDataString(), '00000000000000');
    expect(await d.readStateString(),
        '{"url":"_new_url_","actual_url":"_new_url_","size":7,"downloaded_size":0}');
  });

  test('Load', () async {
    // Create a dumper and set contents.
    var d = await newDumper();
    await d.writeData([1, 2, 3, 4]);
    await d.close();

    // Load the previous dumper.
    var nd = await Dumper.load(d.path, d.currentState.head);
    expect(await nd?.readDataString(), '01020304000000000000');
    expect(await nd?.readStateString(),
        '{"url":"_URL_","actual_url":"_URL_","size":10,"downloaded_size":0}');

    // Load dumper with a different state.
    var head = DataHead(defURL, defURL, 7);
    nd = await Dumper.load(d.path, head);
    expect(nd, null);
  });

  test('Load or create', () async {
    // Create a dumper and set contents.
    var d = await newDumper();
    await d.writeData([1, 2, 3, 4]);
    await d.close();

    // Load the previous dumper.
    var nd = await Dumper.loadOrCreate(d.path, d.currentState.head);
    expect(await nd.readDataString(), '01020304000000000000');
    expect(await nd.readStateString(),
        '{"url":"_URL_","actual_url":"_URL_","size":10,"downloaded_size":0}');

    // Load dumper with a different state.
    var head = DataHead(defURL, defURL, 7);
    nd = await Dumper.loadOrCreate(d.path, head);
    expect(await nd.readDataString(), '00000000000000');
    expect(await nd.readStateString(),
        '{"url":"_URL_","actual_url":"_URL_","size":7,"downloaded_size":0}');
  });
}
