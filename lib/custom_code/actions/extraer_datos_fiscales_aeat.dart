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
// Custom Action: extraerDatosFiscalesAeat
// Sube el PDF "Consulta de Datos Fiscales" de la AEAT al backend y
// devuelve su contenido estructurado.
//
// PARAMETROS:
//   archivoPdf (FFUploadedFile) -> el PDF descargado de la sede de la AEAT
//
// DEVUELVE: un String con JSON.
//   Exito:
//     {"ok": true, "ejercicio": 2025, "casillas": {...},
//      "secciones": [...], "ventas": [...],
//      "perdidas_pendientes": {...}, "avisos": [...],
//      "validaciones": [...]}
//   Error:
//     {"ok": false, "mensaje": "..."}
//
// El mensaje de error viene ya redactado por el backend para mostrarselo
// al usuario tal cual (p. ej. el del PDF sin capa de texto).
//
// Include BuildContext: OFF
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo (http ya esta instalado)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/uploaded_file.dart';

Future<String> extraerDatosFiscalesAeat(FFUploadedFile archivoPdf) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  final bytes = archivoPdf.bytes;
  if (bytes == null || bytes.isEmpty) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se ha podido leer el archivo. Intentalo de nuevo.',
    });
  }

  try {
    final uri = Uri.parse('$base/extraer/datos-fiscales');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: archivoPdf.name ?? 'datos_fiscales.pdf',
      ),
    );

    request.headers.addAll(await _cabeceraAuth());
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    // El backend devuelve UTF-8; hay que decodificarlo explicitamente o los
    // acentos de los nombres de seccion llegan rotos.
    final cuerpo = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final data = jsonDecode(cuerpo) as Map<String, dynamic>;
      return jsonEncode({
        'ok': true,
        'ejercicio': data['ejercicio'],
        'casillas': data['casillas'] ?? {},
        'secciones': data['secciones'] ?? [],
        'ventas': data['ventas_activos_financieros'] ?? [],
        'perdidas_pendientes': data['perdidas_pendientes_compensar'] ?? {},
        'avisos': data['avisos'] ?? [],
        'descuadres': data['descuadres'] ?? [],
        'validaciones': data['validaciones'] ?? [],
      });
    }

    String mensaje;
    try {
      final err = jsonDecode(cuerpo) as Map<String, dynamic>;
      mensaje = err['detail']?.toString() ??
          'No se pudo procesar el documento (error ${response.statusCode}).';
    } catch (_) {
      mensaje =
          'No se pudo procesar el documento (error ${response.statusCode}).';
    }
    return jsonEncode({'ok': false, 'mensaje': mensaje});
  } catch (e) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se pudo conectar con el servidor. Comprueba tu '
          'conexion a internet e intentalo de nuevo.',
    });
  }
}

/// Cabecera de autenticación para la API de cálculo: el ID token de
/// Firebase del usuario que ha iniciado sesión (FirebaseAuth lo renueva solo
/// si ha caducado). Sin sesión no se envía y la API responde 401.
Future<Map<String, String>> _cabeceraAuth() async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  return (token == null || token.isEmpty)
      ? <String, String>{}
      : {'Authorization': 'Bearer $token'};
}
