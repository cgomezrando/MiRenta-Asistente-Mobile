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
// Custom Action: cerrarSesion
// Cierra la sesión actual de Firebase Auth.
// Include BuildContext: OFF
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';

Future<void> cerrarSesion() async {
  try {
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    // Si falla, no hacemos nada crítico; la sesión local se limpia igual.
  }
}
