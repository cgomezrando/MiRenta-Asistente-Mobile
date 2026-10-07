// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ============================================================
// Custom Action: procesarExtractoIBKR
// Flujo completo de un extracto de Interactive Brokers: calcula, pide las
// posiciones previas si hacen falta, enseña el resumen y guarda a través de
// guardarResultadoBroker (que consolida con el resto de brókeres).
//
// PARÁMETROS: context, archivoCsv (FFUploadedFile), anioEjercicio (int)
// DEVUELVE: 'true|gananciasLargas|perdidasLargas|noDeducibles|gananciasCortas|perdidasCortas'
// Include BuildContext: ON. Paquetes: ninguno nuevo.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/uploaded_file.dart';
import '/custom_code/actions/index.dart';

Future<String> procesarExtractoIBKR(
  BuildContext context,
  FFUploadedFile archivoCsv,
  int anioEjercicio,
) async {
  final bytesArchivo = archivoCsv.bytes;
  if (bytesArchivo == null || bytesArchivo.isEmpty) {
    return 'false|0|0|0|0|0';
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ventanaCargando('Procesando el extracto de IBKR...'),
  );

  String resultadoJson = await calcularGananciasIBKR(
    archivoCsv,
    anioEjercicio,
    '[]',
  );

  Map<String, dynamic> data;
  try {
    data = jsonDecode(resultadoJson) as Map<String, dynamic>;
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    return 'false|0|0|0|0|0';
  }

  if (data['ok'] != true) {
    if (context.mounted) Navigator.pop(context);
    await showDialog(
      context: context,
      builder: (ctx) => _ventanaApp(
        titulo: 'Interactive Brokers',
        icono: Icons.error_outline,
        ancho: 440,
        onCerrar: () => Navigator.pop(ctx),
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('No se ha podido procesar el extracto'),
            const SizedBox(height: 8),
            _parrafo(data['mensaje']?.toString() ?? 'Error desconocido.'),
          ],
        ),
        botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
      ),
    );
    return 'false|0|0|0|0|0';
  }

  final pendientes = (data['simbolos_pendientes'] as List?) ?? [];
  String posicionesPreviasJson = '[]';

  if (pendientes.isNotEmpty) {
    if (context.mounted) Navigator.pop(context);
    posicionesPreviasJson = await pedirPosicionesPrevias(
      context,
      resultadoJson,
      '[]',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ventanaCargando('Recalculando con tus posiciones...'),
    );

    resultadoJson = await calcularGananciasIBKR(
      archivoCsv,
      anioEjercicio,
      posicionesPreviasJson,
    );
    try {
      data = jsonDecode(resultadoJson) as Map<String, dynamic>;
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      return 'false|0|0|0|0|0';
    }
  }

  if (context.mounted) Navigator.pop(context);

  double num_(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  final gananciasLargas = num_(data['ganancias_largas']);
  final perdidasLargas = num_(data['perdidas_largas']);
  final perdidasNoDeducibles = num_(data['perdidas_no_deducibles_largas']);
  final gananciasCortas = num_(data['ganancias_cortas']);
  final perdidasCortas = num_(data['perdidas_cortas']);
  // El resumen (operaciones, resultado por valor, comisiones, dividendos)
  // lo enseña mostrarResumenBolsa cuando terminan todos los documentos.

  // Guardar SIEMPRE a través de guardarResultadoBroker: consolida con el
  // resto de brókeres y aplica la regla de los 2 meses entre todos.
  if (!context.mounted) return 'false|0|0|0|0|0';
  final guardado = await guardarResultadoBroker(
    context,
    data['id_broker']?.toString() ?? 'ibkr',
    'Interactive Brokers',
    resultadoJson,
  );
  if (!guardado.startsWith('true')) {
    return 'false|0|0|0|0|0';
  }

  return 'true|$gananciasLargas|$perdidasLargas|$perdidasNoDeducibles|$gananciasCortas|$perdidasCortas';
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
