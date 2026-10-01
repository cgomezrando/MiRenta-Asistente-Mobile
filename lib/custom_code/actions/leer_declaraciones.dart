// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

Future<String> leerDeclaraciones() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return '{"error": true, "mensaje": "No hay usuario autenticado"}';
    }

    final query = await FirebaseFirestore.instance
        .collection('declarations')
        .where('userId', isEqualTo: uid)
        .get();

    final List<Map<String, dynamic>> lista = [];
    for (final doc in query.docs) {
      final d = doc.data();
      lista.add({
        'id': doc.id,
        'year': d['year'] ?? 0,
        'result': (d['result'] ?? 0).toDouble(),
        'toRefund': d['toRefund'] ?? true,
        'status': d['status'] ?? '',
        'createdAt':
            (d['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
      });
    }

    // Ordenar por fecha, más recientes primero
    lista.sort(
        (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

    return jsonEncode({'ok': true, 'declaraciones': lista});
  } catch (e) {
    return '{"error": true, "mensaje": "$e"}';
  }
}
