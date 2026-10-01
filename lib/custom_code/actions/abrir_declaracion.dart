// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

Future<String> abrirDeclaracion(String declaracionId) async {
  try {
    // Leer el documento de Firebase
    final doc = await FirebaseFirestore.instance
        .collection('declarations')
        .doc(declaracionId)
        .get();

    if (!doc.exists) {
      return '{"error": true, "mensaje": "No se encontró la declaración"}';
    }

    final data = doc.data()!;
    final answersJson = data['answers'] ?? '{}';
    final Map<String, dynamic> respuestas = jsonDecode(answersJson);

    // Restaurar las respuestas en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // Limpiar respuestas anteriores
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith('answer_')) {
        await prefs.remove(key);
      }
    }
    // Cargar las de esta declaración
    for (final entry in respuestas.entries) {
      await prefs.setString('answer_${entry.key}', entry.value.toString());
    }

    // Recalcular con las respuestas restauradas
    final resultadoJson = await calcularDeclaracion();
    return resultadoJson;
  } catch (e) {
    return '{"error": true, "mensaje": "$e"}';
  }
}
