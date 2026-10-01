// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

/// ============================================================
// Custom Action: calcularGananciasIBKR
// Sube un extracto de actividad de Interactive Brokers (Activity
// Statement, CSV) y calcula ganancias/pérdidas patrimoniales con soporte
// de posiciones LARGAS y CORTAS, convirtiendo automáticamente a euros
// las operaciones en otras divisas.
//
// PARÁMETROS:
//   archivoCsv (FFUploadedFile) -> el extracto de IBKR
//   anioEjercicio (int) -> año de la declaración, p. ej. 2026
//   posicionesPreviasJson (String) -> JSON de posiciones previas al
//       periodo ya aportadas por el usuario (usa '[]' la primera vez)
//
// DEVUELVE: un String con JSON:
//   Éxito:
//     {"ok": true, "ganancias_largas": .., "perdidas_largas": ..,
//      "ganancias_cortas": .., "perdidas_cortas": ..,
//      "simbolos_pendientes": [...], "avisos": [...],
//      "posiciones_abiertas": [...]}
//   Error:
//     {"ok": false, "mensaje": "..."}
//
// Si 'simbolos_pendientes' no está vacío, hay que pedirle al usuario la
// posición previa de esos valores (fecha, cantidad, precio, moneda) y
// volver a llamar a esta acción con 'posicionesPreviasJson' actualizado
// (acumulando lo ya aportado + lo nuevo) hasta que quede vacío.
//
// Include BuildContext: OFF
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/uploaded_file.dart';

Future<String> calcularGananciasIBKR(
  FFUploadedFile archivoCsv,
  int anioEjercicio,
  String posicionesPreviasJson,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  final bytes = archivoCsv.bytes;
  if (bytes == null || bytes.isEmpty) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se ha podido leer el archivo. Inténtalo de nuevo.',
    });
  }

  try {
    final uri =
        Uri.parse('$base/calcular/fifo/broker?anio_ejercicio=$anioEjercicio');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: archivoCsv.name ?? 'extracto_ibkr.csv',
      ),
    );
    request.fields['posiciones_previas_json'] =
        posicionesPreviasJson.isEmpty ? '[]' : posicionesPreviasJson;

    request.headers.addAll(await _cabeceraAuth());
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonEncode({
        'ok': true,
        'ganancias_largas': data['ganancias_posiciones_largas'] ?? 0.0,
        'perdidas_largas': data['perdidas_posiciones_largas'] ?? 0.0,
        'perdidas_no_deducibles_largas':
            data['perdidas_no_deducibles_largas'] ?? 0.0,
        'ganancias_cortas': data['ganancias_posiciones_cortas'] ?? 0.0,
        'perdidas_cortas': data['perdidas_posiciones_cortas'] ?? 0.0,
        'posiciones_abiertas': data['posiciones_abiertas'] ?? [],
        'simbolos_pendientes':
            data['simbolos_con_posicion_previa_pendiente'] ?? [],
        'avisos': data['avisos'] ?? [],
        'detalle_largas': data['detalle_largas'] ?? [],
        'detalle_cortas': data['detalle_cortas'] ?? [],
        // Huella fiscal para la regla de los 2 meses entre brókeres.
        'huella': data['huella'],
        'id_broker': data['id_broker'],
        // Dividendos, intereses y retenciones del extracto (M05 / M15).
        'rendimientos': data['rendimientos'],
        // Resumen de operativa (operaciones, comisiones, resultado por valor).
        'operativa': data['operativa'],
      });
    } else {
      String mensaje;
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        mensaje = err['detail']?.toString() ??
            'No se pudo procesar el archivo (error ${response.statusCode}).';
      } catch (_) {
        mensaje =
            'No se pudo procesar el archivo (error ${response.statusCode}).';
      }
      return jsonEncode({'ok': false, 'mensaje': mensaje});
    }
  } catch (e) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se pudo conectar con el servidor. Comprueba tu '
          'conexión a internet e inténtalo de nuevo.',
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
