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
// Custom Action: calcularGananciasFifo
// PASO 1 del cálculo FIFO. Sube el CSV de operaciones (compras/ventas de
// acciones, fondos, ETFs) al backend, que aplica la regla FIFO y detecta
// la regla de los 2 meses (Art. 33.5.f LIRPF) usando SOLO lo que hay en
// el propio archivo.
//
// IMPORTANTE: el resultado puede incluir 'perdidas_a_confirmar': ventas
// con pérdida que el backend considera deducibles porque no ha
// encontrado una recompra DENTRO DEL ARCHIVO, pero el usuario podría
// haber recomprado esos mismos valores por otro banco/broker que no
// está en este CSV. Hay que preguntárselo uno por uno (ver
// mostrarConfirmacionFifo) antes de dar el resultado por definitivo.
//
// PARÁMETROS:
//   archivoCsv (FFUploadedFile) -> el archivo que sube el usuario
//   anioEjercicio (int) -> año de la declaración, p. ej. 2025
//
// DEVUELVE: un String con JSON:
//   Éxito:
//     {"ok": true, "ganancias": .., "perdidas": .., "perdidas_no_deducibles": ..,
//      "posiciones_abiertas": [...], "perdidas_a_confirmar": [...],
//      "detalle": [...], "avisos": [...]}
//   Error:
//     {"ok": false, "mensaje": "..."}
//
// Include BuildContext: OFF
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

Future<String> calcularGananciasFifo(
  String contenidoCsv,
  int anioEjercicio,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  if (contenidoCsv.isEmpty) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se ha podido leer el archivo. Inténtalo de nuevo.',
    });
  }
  final bytes = utf8.encode(contenidoCsv);

  try {
    final uri = Uri.parse('$base/calcular/fifo?anio_ejercicio=$anioEjercicio');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: 'operaciones.csv',
      ),
    );

    request.headers.addAll(await _cabeceraAuth());
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonEncode({
        'ok': true,
        'ganancias': data['ganancias_patrimoniales'] ?? 0.0,
        'perdidas': data['perdidas_patrimoniales'] ?? 0.0,
        'perdidas_no_deducibles': data['perdidas_no_deducibles'] ?? 0.0,
        'ganancias_cortas': data['ganancias_posiciones_cortas'] ?? 0.0,
        'perdidas_cortas': data['perdidas_posiciones_cortas'] ?? 0.0,
        'posiciones_abiertas': data['posiciones_abiertas'] ?? [],
        'perdidas_a_confirmar': data['perdidas_a_confirmar'] ?? [],
        'avisos_ejercicio_anterior': data['avisos_ejercicio_anterior'] ?? [],
        'revisar_ejercicio_anterior': data['revisar_ejercicio_anterior'] ?? [],
        'avisos': data['avisos'] ?? [],
        'detalle': data['detalle_operaciones'] ?? [],
        'resultado_previo_raw': data,
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
