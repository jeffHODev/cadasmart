import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const bool DEBUG = false;
String _APP_PATH = '';
Random random = Random.secure();

void appInitialize(BuildContext context) async {
  await _getSystemDir();
  _decodeResource();
}
Future<void> _getSystemDir() async {
  if (_APP_PATH == null || _APP_PATH.length < 1) {
    Directory directory = DEBUG
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    _APP_PATH = directory.path;
  }
}

void _decodeResource() async {
  rootBundle.load('assets/blockly.zip').then((ByteData bytedatas) {
    final archive = ZipDecoder().decodeBytes(bytedatas.buffer.asUint8List());
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(_APP_PATH + '/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(_APP_PATH + '/' + filename)..create(recursive: true);
      }
    }
  });
}

String getHtmlUrl(String filename) {
  return 'file://$_APP_PATH/blockly/$filename';
}
