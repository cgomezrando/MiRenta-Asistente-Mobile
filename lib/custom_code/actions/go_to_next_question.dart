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

Future<bool> goToNextQuestion() async {
  final visibles = FFAppState().visibleQuestions;
  final currentId = FFAppState().currentQuestionId;

  final currentIndex = visibles.indexWhere((q) => q.id == currentId);
  if (currentIndex == -1) return false;

  // Buscar la siguiente pregunta que deba mostrarse
  int nextIndex = currentIndex + 1;
  while (nextIndex < visibles.length) {
    final q = visibles[nextIndex];
    // Preguntas de sí/no que ya han contestado los documentos importados
    // (p. ej. "¿has recibido dividendos?" cuando el extracto del bróker
    // trae dividendos): se saltan; el importe se confirma en la pregunta
    // siguiente. La marca la ponen guardarResultadoBroker y
    // procesarDatosFiscales en answer__auto_<id>.
    final auto = await getAnswer('_auto_${q.id}');
    if (auto == '1') {
      nextIndex++;
      continue;
    }
    if (q.conditionField.isEmpty) break; // sin condición: mostrar
    final answered = await getAnswer(q.conditionField);
    if (answered == q.conditionValue) break; // condición cumplida: mostrar
    nextIndex++; // no se cumple: saltar
  }

  // No hay más preguntas válidas: fin
  if (nextIndex >= visibles.length) {
    return false;
  }

  final next = visibles[nextIndex];

  FFAppState().update(() {
    FFAppState().navigationHistory = [
      ...FFAppState().navigationHistory,
      currentId,
    ];
    FFAppState().currentQuestionId = next.id;
    FFAppState().currentModule = next.module;
  });

  return true;
}
