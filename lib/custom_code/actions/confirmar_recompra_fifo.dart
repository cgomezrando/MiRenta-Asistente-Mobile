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
// Custom Action: confirmarRecompraFifo
// PASO 2 del cálculo FIFO. Muestra un diálogo con hasta tres bloques:
//
//   1. AVISOS AUTOMÁTICOS DEL EJERCICIO ANTERIOR (informativo): ventas
//      con pérdida del año pasado que, según los propios datos del CSV,
//      quedan invalidadas por una recompra de este año. No hace falta
//      preguntar, ya se sabe con certeza. Solo se informa.
//
//   2. PREGUNTA SOBRE EL EJERCICIO ANTERIOR: compras de este año cuya
//      ventana de 2 meses alcanza un periodo del año pasado sin datos
//      cargados. Se pregunta si hubo una venta con pérdida en ese hueco.
//      Es informativo para que el usuario revise su declaración anterior;
//      NO afecta al cálculo de la declaración de este año.
//
//   3. CONFIRMACIÓN DE RECOMPRAS DE ESTE EJERCICIO (ya existente):
//      pérdidas de ESTE año que serían deducibles según el CSV, salvo que
//      el usuario confirme una recompra por otra vía. Esta SÍ afecta al
//      resultado y se envía al backend para el ajuste final.
//
// Si no hay nada en ninguno de los tres bloques, no muestra nada.
//
// PARÁMETROS:
//   context (BuildContext)
//   resultadoFifoJson (String) -> el JSON completo que devolvió
//       calcularGananciasFifo (el que tiene 'resultado_previo_raw')
//
// DEVUELVE: un String con formato
//   'true|ganancias|perdidas|perdidasNoDeducibles|gananciasCortas|perdidasCortas|revisarAnioAnterior'
// (o 'false|0|0|0|0|0|false'). Siempre el mismo formato, haya o no diálogo.
// Además deja el resultado completo del backend (con la 'huella' fiscal) en
// SharedPreferences 'answer_fifo_generico_ultimo_json' para que
// procesarCsvGenerico lo pase a guardarResultadoBroker y la plantilla
// participe en la regla de los 2 meses entre brókeres.
//
// Include BuildContext: ON
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> confirmarRecompraFifo(
  BuildContext context,
  String resultadoFifoJson,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  Map<String, dynamic> entrada;
  try {
    entrada = jsonDecode(resultadoFifoJson) as Map<String, dynamic>;
  } catch (e) {
    return resultadoFifoJson;
  }

  if (entrada['ok'] != true) {
    return resultadoFifoJson;
  }

  final resultadoPrevio =
      entrada['resultado_previo_raw'] as Map<String, dynamic>? ?? {};
  final perdidasAConfirmar =
      (resultadoPrevio['perdidas_a_confirmar'] as List?) ?? [];
  final avisosEjercicioAnterior =
      (resultadoPrevio['avisos_ejercicio_anterior'] as List?) ?? [];
  final revisarEjercicioAnterior =
      (resultadoPrevio['revisar_ejercicio_anterior'] as List?) ?? [];

  final hayAlgoQueMostrar = perdidasAConfirmar.isNotEmpty ||
      avisosEjercicioAnterior.isNotEmpty ||
      revisarEjercicioAnterior.isNotEmpty;

  // Si no hay nada que mostrar, devolvemos el resultado sin más
  if (!hayAlgoQueMostrar) {
    // El resultado completo del backend (con la 'huella' fiscal para la
    // regla de los 2 meses entre brókeres) se deja aquí para que
    // procesarCsvGenerico lo guarde a través de guardarResultadoBroker.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'answer_fifo_generico_ultimo_json', jsonEncode(resultadoPrevio));
    } catch (_) {}
    // Mismo formato que el camino con confirmaciones; antes devolvía un JSON
    // y procesarCsvGenerico, que espera 'true|...', no guardaba nada.
    double n(dynamic v) =>
        v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
    final g =
        n(entrada['ganancias'] ?? resultadoPrevio['ganancias_patrimoniales']);
    final p =
        n(entrada['perdidas'] ?? resultadoPrevio['perdidas_patrimoniales']);
    final nd = n(entrada['perdidas_no_deducibles'] ??
        resultadoPrevio['perdidas_no_deducibles']);
    final gc = n(entrada['ganancias_cortas'] ??
        resultadoPrevio['ganancias_posiciones_cortas']);
    final pc = n(entrada['perdidas_cortas'] ??
        resultadoPrevio['perdidas_posiciones_cortas']);
    return 'true|$g|$p|$nd|$gc|$pc|false';
  }

  // Respuestas del usuario para el bloque 3 (SÍ afecta al cálculo)
  final Map<String, bool> respuestas = {
    for (final p in perdidasAConfirmar)
      '${p['activo']}|${p['fecha_venta']}': false,
  };
  // Respuestas del usuario para el bloque 2 (informativo, año anterior)
  final Map<String, bool> respuestasAnioAnterior = {
    for (final p in revisarEjercicioAnterior) p['activo'].toString(): false,
  };

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        Widget tituloBloque(String texto) => Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(texto,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kAzul)),
            );

        // Sí / No con el mismo aspecto que las opciones del cuestionario.
        Widget botonesSiNo(bool? valorActual, void Function(bool) onTap) {
          Widget opcion(String texto, bool valor) {
            final sel = valorActual == valor;
            return InkWell(
              onTap: () => onTap(valor),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? _kAzul : Colors.white,
                  border: Border.all(color: sel ? _kAzul : _kBorde),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(texto,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _kTexto)),
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(child: opcion('Sí', true)),
              const SizedBox(width: 10),
              Expanded(child: opcion('No', false)),
            ],
          );
        }

        return _ventanaApp(
          titulo: 'Regla de los dos meses',
          icono: Icons.help_outline,
          ancho: 500,
          cuerpo: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tituloVentana('Antes de continuar'),
              const SizedBox(height: 12),

              // --- BLOQUE 1: avisos automáticos del ejercicio anterior ---
              if (avisosEjercicioAnterior.isNotEmpty) ...[
                tituloBloque('Revisa tu declaración del año anterior'),
                ...avisosEjercicioAnterior.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _avisoCaja(a['mensaje'].toString()),
                    )),
                const SizedBox(height: 8),
              ],

              // --- BLOQUE 2: preguntar por el ejercicio anterior ---
              if (revisarEjercicioAnterior.isNotEmpty) ...[
                tituloBloque('Una pregunta sobre el año anterior'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _parrafo('Esto es solo informativo: no cambia el '
                      'cálculo de este año, pero puede afectar a tu '
                      'declaración del año pasado.'),
                ),
                ...revisarEjercicioAnterior.map((p) {
                  final activo = p['activo'].toString();
                  final inicio = p['periodo_sin_datos_inicio'].toString();
                  final fin = p['periodo_sin_datos_fin'].toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _tarjeta(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activo,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kTexto)),
                        const SizedBox(height: 2),
                        _parrafo(
                            '¿Vendiste esto con pérdida entre el $inicio '
                            'y el $fin?',
                            tam: 12.5),
                        const SizedBox(height: 10),
                        botonesSiNo(
                          respuestasAnioAnterior[activo],
                          (v) => setState(
                              () => respuestasAnioAnterior[activo] = v),
                        ),
                      ],
                    )),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // --- BLOQUE 3: confirmación de recompras de este ejercicio ---
              if (perdidasAConfirmar.isNotEmpty) ...[
                tituloBloque('Confirma estas posibles recompras'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _parrafo('¿Volviste a comprar alguno de estos '
                      'valores por OTRO banco o bróker (fuera del archivo '
                      'cargado), dentro de los 2 meses antes o después de '
                      'venderlo?'),
                ),
                ...perdidasAConfirmar.map((p) {
                  final clave = '${p['activo']}|${p['fecha_venta']}';
                  final activo = p['activo'].toString();
                  final fecha = p['fecha_venta'].toString();
                  final importe = (p['importe_perdida'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _tarjeta(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activo,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kTexto)),
                        const SizedBox(height: 2),
                        _parrafo(
                            'Vendido el $fecha · Pérdida: '
                            '${_eur(importe)}',
                            tam: 12.5),
                        const SizedBox(height: 10),
                        botonesSiNo(
                          respuestas[clave],
                          (v) => setState(() => respuestas[clave] = v),
                        ),
                      ],
                    )),
                  );
                }),
              ],
            ],
          ),
          botones: [_botonPrimario('Continuar', () => Navigator.pop(ctx))],
        );
      });
    },
  );

  // Solo el BLOQUE 3 (recompras de este ejercicio) afecta al cálculo y se
  // envía al backend. El BLOQUE 2 (año anterior) es informativo: no hace
  // falta ajustar nada, pero si el usuario respondió "Sí" en alguno,
  // añadimos un aviso al resultado final para reforzar el mensaje.
  final confirmaciones = perdidasAConfirmar
      .where((p) => respuestas['${p['activo']}|${p['fecha_venta']}'] == true)
      .map((p) => {
            'activo': p['activo'],
            'fecha_venta': p['fecha_venta'],
          })
      .toList();

  final activosConfirmadosAnioAnterior = respuestasAnioAnterior.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .toList();

  try {
    final response = await http.post(
      Uri.parse('$base/calcular/fifo/confirmar'),
      headers: {
        'Content-Type': 'application/json',
        ...await _cabeceraAuth(),
      },
      body: jsonEncode({
        'resultado_previo': resultadoPrevio,
        'confirmaciones': confirmaciones,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Resultado ya ajustado con las confirmaciones (y su 'huella'), para
      // que procesarCsvGenerico lo guarde a través de guardarResultadoBroker.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'answer_fifo_generico_ultimo_json', jsonEncode(data));
      } catch (_) {}
      final ganancias =
          (data['ganancias_patrimoniales'] as num?)?.toDouble() ?? 0.0;
      final perdidas =
          (data['perdidas_patrimoniales'] as num?)?.toDouble() ?? 0.0;
      final perdidasNoDeducibles =
          (data['perdidas_no_deducibles'] as num?)?.toDouble() ?? 0.0;
      final gananciasCortas =
          (data['ganancias_posiciones_cortas'] as num?)?.toDouble() ?? 0.0;
      final perdidasCortas =
          (data['perdidas_posiciones_cortas'] as num?)?.toDouble() ?? 0.0;
      final revisarAnioAnterior = activosConfirmadosAnioAnterior.isNotEmpty;
      // Formato: ok|ganancias|perdidas|perdidasNoDeducibles|gananciasCortas|perdidasCortas|revisarAnioAnterior
      return 'true|$ganancias|$perdidas|$perdidasNoDeducibles|$gananciasCortas|$perdidasCortas|$revisarAnioAnterior';
    } else {
      return 'false|0|0|0|0|0|false';
    }
  } catch (e) {
    return 'false|0|0|0|0|0|false';
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

// ============================================================
// Estética común de las ventanas emergentes de la app: la misma que usa
// showInterviewDialog (cabecera azul con icono y título, cuerpo crema,
// botones a ancho completo: secundario blanco con borde, primario azul).
// Este bloque se repite en cada Custom Action porque FlutterFlow no permite
// compartir widgets entre acciones sin declararlos como Custom Widget.
// ============================================================
const Color _kAzul = Color(0xFF1B3A6B);
const Color _kCrema = Color(0xFFFAFAF8);
const Color _kTexto = Color(0xFF2C3E50);
const Color _kTextoSec = Color(0xFF6B7280);
const Color _kBorde = Color(0xFFE5E7EB);
const Color _kOro = Color(0xFFC9A961);
const Color _kVerde = Color(0xFF2E7D32);
const Color _kRojo = Color(0xFFB3261E);
const Color _kGris = Color(0xFF9CA3AF);

Widget _ventanaApp({
  required String titulo,
  required Widget cuerpo,
  IconData icono = Icons.assignment_outlined,
  List<Widget> botones = const [],
  Widget? pie,
  VoidCallback? onCerrar,
  double ancho = 600,
}) {
  // Se adapta a la pantalla: en iPhone (ancho < 500) usa márgenes y
  // rellenos más pequeños, ocupa casi todo el ancho y apila los botones
  // (el principal arriba) para que los textos largos no se corten.
  return Builder(builder: (context) {
    final pantalla = MediaQuery.of(context).size;
    final estrecho = pantalla.width < 500;
    final margenLateral = estrecho ? 12.0 : 24.0;
    final relleno = estrecho ? 16.0 : 24.0;
    final altoMax = pantalla.height * 0.9 < 720 ? pantalla.height * 0.9 : 720.0;
    final apilar = estrecho && botones.length > 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: margenLateral, vertical: estrecho ? 16 : 24),
      child: Container(
        width: ancho,
        constraints: BoxConstraints(maxHeight: altoMax),
        decoration: BoxDecoration(
          color: _kCrema,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: estrecho ? 16 : 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kAzul,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icono, size: 20, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(titulo,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  if (onCerrar != null)
                    InkWell(
                      onTap: onCerrar,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(relleno, 20, relleno, 8),
                child: cuerpo,
              ),
            ),
            if (pie != null)
              Padding(
                padding: EdgeInsets.fromLTRB(relleno, 10, relleno, 0),
                child: pie,
              ),
            if (botones.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    relleno, 12, relleno, estrecho ? 16 : 20),
                child: apilar
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = botones.length - 1; i >= 0; i--) ...[
                            botones[i],
                            if (i > 0) const SizedBox(height: 10),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          for (var i = 0; i < botones.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: botones[i]),
                          ],
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  });
}

Widget _botonPrimario(String texto, VoidCallback? onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: onTap != null ? _kAzul : _kGris,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(texto,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    ),
  );
}

Widget _botonSecundario(String texto, VoidCallback? onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kAzul),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(texto,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _kAzul)),
      ),
    ),
  );
}

Widget _tituloVentana(String t) => Text(t,
    style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600, color: _kTexto));

Widget _parrafo(String t, {double tam = 13.5, Color color = _kTextoSec}) =>
    Text(t, style: TextStyle(fontSize: tam, color: color, height: 1.45));

Widget _tarjeta(Widget hijo, {Color? borde, Color? fondo}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo ?? Colors.white,
        border: Border.all(color: borde ?? _kBorde),
        borderRadius: BorderRadius.circular(10),
      ),
      child: hijo,
    );

Widget _avisoCaja(String texto, {Color color = _kOro, IconData? icono}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono ?? Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 12.5, color: _kTexto, height: 1.4)),
          ),
        ],
      ),
    );

Widget _filaDato(String etiqueta, String valor, {bool destacado = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta,
                style: const TextStyle(fontSize: 13.5, color: _kTexto)),
          ),
          Text(valor,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: destacado ? FontWeight.w700 : FontWeight.w600,
                  color: _kTexto)),
        ],
      ),
    );

Widget _ventanaCargando(String texto) => Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: _kCrema,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 24,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(strokeWidth: 2.5, color: _kAzul),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(texto,
                    style: const TextStyle(fontSize: 14, color: _kTexto)),
              ),
            ],
          ),
        ),
      ),
    );

String _eur(double v) {
  final s = v.toStringAsFixed(2);
  final partes = s.split('.');
  final ent =
      partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '$ent,${partes[1]} €';
}
