import 'dart:io';
import 'dart:typed_data';

import 'package:buxing/src/state.dart';

const dataExt = '.bxdown';
const stateExt = '.bxdownstate';

/// Dumper writes data to a disk file.
class Dumper {
  final String path;

  late final File dataFile;
  late final File stateFile;
  RandomAccessFile? _dataRAF;
  State _currentState;

  State get currentState => _currentState;

  Dumper._(this.path, this._currentState) {
    dataFile = File(path + dataExt);
    stateFile = File(path + stateExt);
  }

  Future prepare() async {
    _dataRAF = await dataFile.open(mode: FileMode.append);
  }

  Future close() async {
    return _dataRAF?.close();
  }

  Future writeData(List<int> data) async {
    await _dataRAF?.writeFrom(data);
  }

  Future seek(int poz) async {
    await _dataRAF?.setPosition(poz);
  }

  Future writeState(State state) async {
    _currentState = state;
    await stateFile.writeAsString(state.toJSON());
  }

  static Future<Dumper> create(String dest, State state) async {
    var d = Dumper._(dest, state);

    await d.dataFile.create(recursive: true);
    if (state.head.size >= 0) {
      await d.dataFile.writeAsBytes(Uint8List(state.head.size));
    }

    await d.stateFile.create(recursive: true);
    await d.stateFile.writeAsString(state.toJSON());

    return d;
  }

  static Future<Dumper?> load(String dest, State state,
      {bool logging = false}) async {
    try {
      var d = Dumper._(dest, state);
      if (await d.stateFile.exists() && await d.dataFile.exists()) {
        var localState = State.fromJSON(await d.stateFile.readAsString());

        // Check if local state is not identical to incoming state.
        if (identical(localState, state)) {
          throw Exception('Online state has changed');
        }

        // Check local state size is equal to data size.
        var fileSize = await d.dataFile.length();
        if (localState.head.size != 0 && state.head.size != fileSize) {
          throw Exception(
              'Local state size mismatch ${localState.head.size} != $fileSize');
        }
        return d;
      }
      return null;
    } catch (e) {
      // Corrupted state file, returning null.
      if (logging) {
        // ignore: avoid_print
        print('Error loading state "$e"');
      }
      return null;
    }
  }

  static Future<Dumper> loadOrCreate(String dest, State state,
      {bool logging = false}) async {
    return (await load(dest, state, logging: logging)) ??
        await create(dest, state);
  }
}
