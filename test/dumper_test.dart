import 'dart:convert';

import 'package:convert/convert.dart';

import 'package:buxing/buxing.dart';
import 'package:test/test.dart';

import 'helper/common.dart';

const dataExt = '.bxdown';
const stateExt = '.bxdownstate';

Future<Dumper> newDumper({int size = defSize}) async {
  final file = newFile();
  final head = StateHead(defURL, defURL, size);
  final d = await Dumper.create(file, head);
  if (size > 0) {
    // Set position to start of the file.
    await d.seek(0);
  }
  return d;
}

extension Test on Dumper {
  Future<void> writeString(String s) async {
    await writeData(ascii.encode(s));
  }

  Future<String> readDataString() async {
    final bytes = await dataFile.readAsBytes();
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
    final d = await newDumper();
    expect(d.dataFile.path, d.path + dataExt);
    expect(await d.readDataString(), '00000000000000000000');
    expect(d.stateFile.path, d.path + stateExt);
    expect(await d.readStateString(), d.currentStateJSON());
    await d.close();
  });

  test('Create (size 0)', () async {
    final d = await newDumper(size: 0);
    expect(d.dataFile.path, d.path + dataExt);
    expect(await d.readDataString(), '');
    expect(d.stateFile.path, d.path + stateExt);
    expect(await d.readStateString(), d.currentStateJSON());
    await d.close();
  });

  test('Create and write (size -1)', () async {
    final d = await newDumper(size: -1);
    expect(d.dataFile.path, d.path + dataExt);
    expect(await d.readDataString(), '');
    expect(d.stateFile.path, d.path + stateExt);
    expect(await d.readStateString(), d.currentStateJSON());
    await d.writeString('a');
    expect(await d.readDataString(), '61');

    await d.writeString('b');
    expect(await d.readDataString(), '6162');
    await d.close();
  });

  test('Write and seek', () async {
    final d = await newDumper();
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
    final newURL = Uri.parse('https://__new_url__');
    final head = StateHead(newURL, newURL, newSize);
    d = await Dumper.create(d.path, head);
    expect(await d.readDataString(), '00000000000000');
    expect(await d.readStateString(),
        '{"url":"https://__new_url__","original_url":"https://__new_url__","size":7,"transferred":0}');
  });

  test('Load', () async {
    // Create a dumper and set contents.
    final d = await newDumper();
    await d.writeData([1, 2, 3, 4]);
    await d.close();

    // Load the previous dumper.
    var nd = await Dumper.load(d.path, d.currentState.head);
    expect(await nd!.readDataString(), '01020304000000000000');
    expect(await nd.readStateString(),
        '{"url":"_url_","original_url":"_url_","size":10,"transferred":0}');

    // Load dumper with a different state.
    final head = StateHead(defURL, defURL, 7);
    nd = await Dumper.load(d.path, head);
    expect(nd, null);
  });

  test('Load or create', () async {
    // Create a dumper and set contents.
    final d = await newDumper();
    await d.writeData([1, 2, 3, 4]);
    await d.close();

    // Load the previous dumper.
    var nd = await Dumper.loadOrCreate(d.path, d.currentState.head);
    expect(await nd.readDataString(), '01020304000000000000');
    expect(await nd.readStateString(),
        '{"url":"_url_","original_url":"_url_","size":10,"transferred":0}');

    // Load dumper with a different state.
    final head = StateHead(defURL, defURL, 7);
    nd = await Dumper.loadOrCreate(d.path, head);
    expect(await nd.readDataString(), '00000000000000');
    expect(await nd.readStateString(),
        '{"url":"_url_","original_url":"_url_","size":7,"transferred":0}');
  });

  test('Truncate', () async {
    final d = await newDumper();
    await d.truncate(1);
    expect(d.dataFile.path, d.path + dataExt);
    expect(await d.readDataString(), '00');
    expect(d.stateFile.path, d.path + stateExt);
    expect(await d.readStateString(), d.currentStateJSON());
    await d.close();
  });
}
