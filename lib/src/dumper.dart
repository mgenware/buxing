import 'dart:io';
import 'dart:typed_data';

import 'package:buxing/src/state.dart';

const dataExt = '.bxdown';
const stateExt = '.bxdownstate';

/// Dumper writes data to a disk file.
class Dumper {
  final String path;
  final String dataPath;
  final String statePath;
  RandomAccessFile? _dataFile;

  Dumper._(this.path)
      : dataPath = path + dataExt,
        statePath = path + stateExt;

  Future prepare() async {
    _dataFile = await File(dataPath).open(mode: FileMode.append);
  }

  Future close() async {
    _dataFile?.close();
  }

  Future writeData(List<int> data) async {
    await _dataFile?.writeFrom(data);
  }

  Future seek(int poz) async {
    await _dataFile?.setPosition(poz);
  }

  Future writeState(State state) async {
    await File(statePath).writeAsString(state.toJSON());
  }

  static Future<Dumper> create(String dest, State state) async {
    var d = Dumper._(dest);

    var dataFile = await File(d.dataPath).create(recursive: true);
    dataFile.writeAsBytes(Uint8List(state.size));

    var stateFile = await File(d.statePath).create(recursive: true);
    stateFile.writeAsString(state.toJSON());

    return d;
  }
}
