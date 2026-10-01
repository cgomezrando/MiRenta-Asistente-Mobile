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
// Custom Action: calcularGananciasDegiro
// Sube el "Informe Anual" de DEGIRO (PDF) y calcula ganancias y perdidas
// patrimoniales con el mismo motor FIFO que Interactive Brokers.
//
// PARAMETROS:
//   archivoPdf (FFUploadedFile) -> lo devuelve elegirArchivoPdf()
//   anioEjercicio (int)
//   posicionesPreviasJson (String) -> '[]' la primera vez
//   traspasosConfirmadosJson (String) -> lista JSON de ISIN que el usuario
//       ha confirmado que salieron por traspaso a otro broker ('[]' si ninguno)
//
// DEVUELVE: un String con JSON.
//   Exito: {"ok": true, "ganancias_largas": .., "perdidas_largas": ..,
//           "ganancias_cortas": .., "perdidas_cortas": ..,
//           "simbolos_pendientes": [...], "avisos": [...],
//           "verificacion": {...}, "itf": 40.0}
//   Error: {"ok": false, "mensaje": "..."}
//
// Include BuildContext: OFF
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo (http ya esta instalado)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/uploaded_file.dart';

Future<String> calcularGananciasDegiro(
  FFUploadedFile archivoPdf,
  int anioEjercicio,
  String posicionesPreviasJson,
  String traspasosConfirmadosJson,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  final bytes = archivoPdf.bytes;
  if (bytes == null || bytes.isEmpty) {
    return jsonEncode({
      'ok': false,
      'mensaje': 'No se ha podido leer el archivo. Intentalo de nuevo.',
    });
  }

  try {
    final uri =
        Uri.parse('$base/calcular/fifo/degiro?anio_ejercicio=$anioEjercicio');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'archivo',
        bytes,
        filename: archivoPdf.name ?? 'informe_degiro.pdf',
      ),
    );
    request.fields['posiciones_previas_json'] =
        posicionesPreviasJson.isEmpty ? '[]' : posicionesPreviasJson;
    request.fields['traspasos_confirmados_json'] =
        traspasosConfirmadosJson.isEmpty ? '[]' : traspasosConfirmadosJson;

    request.headers.addAll(await _cabeceraAuth());
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final cuerpo = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final data = jsonDecode(cuerpo) as Map<String, dynamic>;
      return jsonEncode({
        'ok': true,
        'ganancias_largas': data['ganancias_posiciones_largas'] ?? 0.0,
        'perdidas_largas': data['perdidas_posiciones_largas'] ?? 0.0,
        'perdidas_no_deducibles_largas':
            data['perdidas_no_deducibles_largas'] ?? 0.0,
        'ganancias_cortas': data['ganancias_posiciones_cortas'] ?? 0.0,
        'perdidas_cortas': data['perdidas_posiciones_cortas'] ?? 0.0,
        'simbolos_pendientes':
            data['simbolos_con_posicion_previa_pendiente'] ?? [],
        'avisos': data['avisos'] ?? [],
        'verificacion': data['verificacion_degiro'] ?? {},
        'itf': data['impuesto_transacciones_financieras'] ?? 0.0,
        'traspasos_detectados': data['traspasos_detectados'] ?? [],
        'traspasos_salientes': data['traspasos_salientes'] ?? [],
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
    }

    String mensaje;
    try {
      final err = jsonDecode(cuerpo) as Map<String, dynamic>;
      mensaje = err['detail']?.toString() ??
          'No se pudo procesar el informe (error ${response.statusCode}).';
    } catch (_) {
      mensaje =
          'No se pudo procesar el informe (error ${response.statusCode}).';
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
