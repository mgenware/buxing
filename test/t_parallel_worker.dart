import 'dart:convert';

import 'package:buxing/buxing.dart';
import 'package:mock_byte_stream/mock_byte_stream.dart';

// ignore: prefer_single_quotes
const pwString = """BSD 3-Clause License

Copyright (c) 2021, Mgenware (Liu YuanYuan)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
""";
var pwBytes = utf8.encode(pwString);

class TPWConn extends PWConnBase {
  final bool slow;
  TPWConn(Uri url, int position, int size, {this.slow = false})
      : super(url, position, size);

  @override
  Future<Stream<List<int>>> startCore() async {
    var part = pwBytes.sublist(position, position + size);
    var mbs = MockByteStream(part, 50,
        minDelay: Duration(milliseconds: slow ? 200 : 20),
        maxDelay: Duration(milliseconds: slow ? 800 : 100));
    return mbs.stream();
  }

  @override
  TPWConn create(Uri url, int position, int size) {
    return TPWConn(url, position, size);
  }
}

class TParallelWorker extends ParallelWorker {
  final bool slow;
  TParallelWorker({this.slow = false});

  @override
  Future<DataHead> connect(Uri url) async {
    return Future(() => DataHead(url, url, pwBytes.length));
  }

  @override
  PWConnBase createPWConn(Uri url, ConnState connState) {
    return TPWConn(url, connState.position, connState.size, slow: slow);
  }

  @override
  Future<bool> canResume(Uri url) {
    return Future.value(true);
  }
}
