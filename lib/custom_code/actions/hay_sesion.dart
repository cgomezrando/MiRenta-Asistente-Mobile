// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ============================================================
// Custom Action: haySesion
// Devuelve true si hay un usuario con sesión iniciada, false si no.
// Útil para que el botón decida qué opciones mostrar.
// Include BuildContext: OFF
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';

Future<bool> haySesion() async {
  return FirebaseAuth.instance.currentUser != null;
}
