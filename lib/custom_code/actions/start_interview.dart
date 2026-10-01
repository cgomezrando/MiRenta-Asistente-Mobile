// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/app_state.dart';

Future startInterview() async {
  final script = await loadScript();

  // Extraer los módulos únicos del guion, en orden de aparición
  final List<String> modulos = [];
  for (final q in script) {
    if (!modulos.contains(q.module)) {
      modulos.add(q.module);
    }
  }

  FFAppState().update(() {
    FFAppState().fullScript = script;
    FFAppState().visibleQuestions = script;
    FFAppState().activeModules = modulos;
    FFAppState().currentQuestionId = script.first.id;
    FFAppState().currentModule = script.first.module;
    FFAppState().activeDeclarant = 'A';
    FFAppState().navigationHistory = [];
  });
}
