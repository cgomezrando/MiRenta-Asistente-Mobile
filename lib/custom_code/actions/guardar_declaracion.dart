// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

Future<String> guardarDeclaracion(
    double resultado, bool aDevolver, String nombre) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return '{"error": true, "mensaje": "No hay usuario autenticado"}';
    }

    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> respuestas = {};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('answer_')) {
        final id = key.substring('answer_'.length);
        respuestas[id] = prefs.getString(key) ?? '';
      }
    }

    final docRef =
        await FirebaseFirestore.instance.collection('declarations').add({
      'userId': uid,
      'year': 2025,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'completa',
      'name': nombre,
      'result': resultado,
      'toRefund': aDevolver,
      'answers': jsonEncode(respuestas),
    });

    return '{"ok": true, "id": "${docRef.id}"}';
  } catch (e) {
    return '{"error": true, "mensaje": "$e"}';
  }
}
