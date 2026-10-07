// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/app_state.dart';

Future goToPreviousQuestion() async {
  final history = FFAppState().navigationHistory;
  if (history.isEmpty) return;

  final previousId = history.last;
  final visibles = FFAppState().visibleQuestions;
  final previousQuestion = visibles.firstWhere((q) => q.id == previousId);

  FFAppState().update(() {
    FFAppState().navigationHistory = history.sublist(0, history.length - 1);
    FFAppState().currentQuestionId = previousQuestion.id;
    FFAppState().currentModule = previousQuestion.module;
  });
}
