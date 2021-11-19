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
  bool _closed = false;
  int _poz = -1;

  /// Last written state.
  State get currentState => _currentState;

  /// Returns the current file position.
  int get position => _poz;

  static Future<Dumper> _newDumper(String path, State initialState,
      File dataFile, File stateFile, Logger? logger) async {
    var d = Dumper._(path, initialState, dataFile, stateFile, logger);
    await d._prepare();
    return d;
  }

  Dumper._(this.path, this._currentState, this.dataFile, this.stateFile,
      this.logger);

  Future<void> _prepare() async {
    var raf = await dataFile.open(mode: FileMode.append);
    _poz = await raf.length();
    _dataRAF = raf;
  }

  Future<void> complete() async {
    logger?.info('dumper: Completing');
    await close();
    logger?.info('dumper: Deleting state file');
    await stateFile.delete();
    logger?.info('dumper: Renaming data file');
    await dataFile.rename(path);
  }

  /// Releases any resources of the current dumper.
  Future<void> close() async {
    // This check is necessary as [complete] might have called [close].
    if (_closed) {
      return;
    }
    logger?.info('dumper: Closing RAF');
    await _dataRAF!.close();
    _dataRAF = null;
    _closed = true;
  }

  Future<void> writeData(List<int> data) async {
    await _dataRAF!.writeFrom(data);
  }

  Future<void> seek(int poz) async {
    if (currentState.head.size >= 0 && poz >= currentState.head.size) {
      throw Exception(
          'Invalid seek position $poz, maximum allowed ${currentState.head.size - 1}');
    }
    _poz = poz;
    await _dataRAF!.setPosition(poz);
  }

  Future<void> writeState(State state) async {
    _currentState = state;
    await stateFile.writeAsString(state.toJSON());
  }

  Future<void> truncate(int length) async {
    logger?.info('dumper: Truncate data to $length');
    await _dataRAF!.truncate(length);
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
      logger?.error('dumper: Error loading state "$e"');
      return null;
    }
  }

  static Future<Dumper> loadOrCreate(String dest, DataHead head,
      [Logger? logger]) async {
    var state = await load(dest, head, logger);
    if (state != null) {
      logger?.info('dumper: State loaded');
      return state;
    }
    logger?.info('dumper: Creating state');
    return create(dest, head, logger);
  }
}
