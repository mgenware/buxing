import 'dart:io';
import 'dart:typed_data';

import 'package:buxing/buxing.dart';
import 'package:buxing/src/logger.dart';

const dataExt = '.bxdown';
const stateExt = '.bxdownstate';

File getDataFile(String path) {
  return File(path + dataExt);
}

File getStateFile(String path) {
  return File(path + stateExt);
}

/// Dumper writes data to a disk file.
class Dumper {
  final String path;

  final File dataFile;
  final File stateFile;

  Logger? logger;
  RandomAccessFile? _dataRAF;
  State _currentState;

  State get currentState => _currentState;

  static Future<Dumper> _newDumper(String path, State initialState,
      File dataFile, File stateFile, Logger? logger) async {
    var d = Dumper._(path, initialState, dataFile, stateFile, logger);
    await d._prepare();
    return d;
  }

  Dumper._(this.path, this._currentState, this.dataFile, this.stateFile,
      this.logger);

  Future _prepare() async {
    _dataRAF = await dataFile.open(mode: FileMode.append);
  }

  Future complete() async {
    await close();
    logger?.log('dumper: Deleting state file');
    await stateFile.delete();
    logger?.log('dumper: Renaming data file');
    await dataFile.rename(path);
  }

  Future close() async {
    logger?.log('dumper: Closing RAF');
    await _dataRAF!.close();
    _dataRAF = null;
  }

  Future writeData(List<int> data) async {
    await _dataRAF!.writeFrom(data);
  }

  Future seek(int poz) async {
    if (currentState.head.size >= 0 && poz >= currentState.head.size) {
      throw Exception(
          'Invalid seek position $poz, maximum allowed ${currentState.head.size - 1}');
    }
    logger?.log('dumper: Seek: $poz');
    await _dataRAF?.setPosition(poz);
  }

  Future writeState(State state) async {
    _currentState = state;
    await stateFile.writeAsString(state.toJSON());
  }

  static Future<Dumper> create(String dest, DataHead head,
      [Logger? logger]) async {
    var state = State(head);
    var stateFile = getStateFile(dest);
    var dataFile = getDataFile(dest);

    await dataFile.create(recursive: true);
    if (head.size >= 0) {
      await dataFile.writeAsBytes(Uint8List(head.size));
    }

    await stateFile.create(recursive: true);

    var d = await Dumper._newDumper(dest, state, dataFile, stateFile, logger);
    await d.writeState(state);
    return d;
  }

  static Future<Dumper?> load(String dest, DataHead head,
      [Logger? logger]) async {
    try {
      var stateFile = getStateFile(dest);
      var dataFile = getDataFile(dest);
      if (await stateFile.exists() && await dataFile.exists()) {
        var localState = State.fromJSON(await stateFile.readAsString());
        // Check if two states have the same head.
        if (identical(localState.head, head)) {
          throw Exception('Online state has changed');
        }

        // Make sure data file size is less than state filesize.
        var fileSize = await dataFile.length();
        if (head.size >= 0 && fileSize > head.size) {
          throw Exception(
              'Local data size is greater than remote file size, $fileSize != ${head.size}');
        }

        return await Dumper._newDumper(
            dest, localState, dataFile, stateFile, logger);
      }
      return null;
    } catch (e) {
      // Corrupted state file, returning null.
      logger?.log('dumper: Error loading state "$e"');
      return null;
    }
  }

  static Future<Dumper> loadOrCreate(String dest, DataHead head,
      [Logger? logger]) async {
    var state = await load(dest, head, logger);
    if (state != null) {
      logger?.log('dumper: State loaded');
      return state;
    }
    logger?.log('dumper: Creating state');
    return create(dest, head, logger);
  }
}
