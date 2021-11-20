import 'dart:io';
import 'dart:math';
import 'package:buxing/buxing.dart';
import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

import 't_worker.dart';

var uuid = Uuid();

var defURL = Uri.parse('_url_');
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

class TaskWrapper {
  late final Task task;
  String initialState = '';
  int initialPoz = -1;
  List<double> progressValues = [];

  TaskStatus get status => task.status;
  State? get state => task.state;
  String get destFile => task.destFile;
  String? get stateFile => task.stateFile;

  TaskWrapper({WorkerBase? worker, String? destFile}) {
    if (worker == null) {
      var tWorker = TWorker();
      tWorker.size = defSize;
      worker = tWorker;
    }
    task = Task(
      defURL,
      destFile ?? newFile(),
      worker: worker,
    );
    task.onBeforeDownload = (state, poz) {
      initialState = state.toJSON();
      initialPoz = poz;
    };
    task.onProgress = (info) {
      progressValues
          .add(_roundDouble(info.downloaded.toDouble() / info.total, 2));
    };
  }

  Future<void> start() {
    return task.start();
  }

  Future<String> readDestData() async {
    var bytes = await File(task.destFile).readAsBytes();
    return hex.encode(bytes);
  }

  Future<String> readDestString() async {
    return File(task.destFile).readAsString();
  }

  Future<String> readStateString() async {
    return File(task.stateFile!).readAsString();
  }

  Future<void> close() {
    return task.close();
  }

  double _roundDouble(double val, int places) {
    num mod = pow(10.0, places);
    return (val * mod).round().toDouble() / mod;
  }
}
