// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:file_picker/file_picker.dart';
import '/flutter_flow/uploaded_file.dart';

Future<FFUploadedFile?> elegirArchivoCsv() async {
  final resultado = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );
  if (resultado == null || resultado.files.isEmpty) {
    return null; // el usuario cancelo
  }
  final f = resultado.files.first;
  final bytes = f.bytes;
  if (bytes == null || bytes.isEmpty) {
    return null;
  }
  return FFUploadedFile(
    name: f.name,
    bytes: bytes,
  );
}
