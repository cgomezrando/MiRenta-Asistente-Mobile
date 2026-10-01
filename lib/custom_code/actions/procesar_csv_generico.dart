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
// Custom Action: procesarCsvGenerico
// Flujo completo de la plantilla genérica (CSV): calcula, pasa por
// confirmarRecompraFifo y guarda a través de guardarResultadoBroker, con la
// 'huella' fiscal para que participe en la regla de los 2 meses entre
// brókeres igual que IBKR y DEGIRO.
//
// PARÁMETROS: context, archivoCsv (FFUploadedFile), anioEjercicio (int)
// Include BuildContext: ON. Paquetes: ninguno nuevo.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/uploaded_file.dart';
import '/custom_code/actions/index.dart';

Future<void> procesarCsvGenerico(
  BuildContext context,
  FFUploadedFile archivoCsv,
  int anioEjercicio,
) async {
  final bytesArchivo = archivoCsv.bytes;
  if (bytesArchivo == null || bytesArchivo.isEmpty) {
    return;
  }
  final contenidoCsv = utf8.decode(bytesArchivo, allowMalformed: true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ventanaCargando('Procesando la plantilla...'),
  );

  final resultadoJson =
      await calcularGananciasFifo(contenidoCsv, anioEjercicio);

  if (context.mounted) Navigator.pop(context);

  Map<String, dynamic> data;
  try {
    data = jsonDecode(resultadoJson) as Map<String, dynamic>;
  } catch (e) {
    return;
  }
  if (data['ok'] != true) {
    await showDialog(
      context: context,
      builder: (ctx) => _ventanaApp(
        titulo: 'Plantilla de operaciones',
        icono: Icons.error_outline,
        ancho: 440,
        onCerrar: () => Navigator.pop(ctx),
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('No se ha podido procesar el archivo'),
            const SizedBox(height: 8),
            _parrafo(data['mensaje']?.toString() ?? 'Error desconocido.'),
          ],
        ),
        botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
      ),
    );
    return;
  }

  // Se limpia el resultado anterior para no reutilizar nunca una huella vieja.
  try {
    await (await SharedPreferences.getInstance())
        .remove('answer_fifo_generico_ultimo_json');
  } catch (_) {}
  final resultadoFinalTexto =
      await confirmarRecompraFifo(context, resultadoJson);
  final partes = resultadoFinalTexto.split('|');
  if (partes.isEmpty || partes[0] != 'true') return;

  final gananciasLargas = double.tryParse(partes[1]) ?? 0.0;
  final perdidasLargas = double.tryParse(partes[2]) ?? 0.0;
  final gananciasCortas =
      partes.length > 4 ? (double.tryParse(partes[4]) ?? 0.0) : 0.0;
  final perdidasCortas =
      partes.length > 5 ? (double.tryParse(partes[5]) ?? 0.0) : 0.0;

  // El resultado completo del backend (con la 'huella' fiscal) lo deja
  // confirmarRecompraFifo en preferencias; así esta vía participa en la
  // regla de los 2 meses entre brókeres igual que IBKR y DEGIRO.
  if (!context.mounted) return;
  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> completo = {};
  try {
    completo = Map<String, dynamic>.from(jsonDecode(
        prefs.getString('answer_fifo_generico_ultimo_json') ?? '{}'));
  } catch (_) {}
  final Map<String, dynamic> paraGuardar = completo['huella'] is Map
      ? {
          'ok': true,
          'huella': completo['huella'],
          'operativa': completo['operativa'],
        }
      : {
          'ok': true,
          'totales': {
            'ganancias': gananciasLargas,
            'perdidas': perdidasLargas,
            'ganancias_cortas': gananciasCortas,
            'perdidas_cortas': perdidasCortas,
          },
        };
  if (!context.mounted) return;
  final guardado = await guardarResultadoBroker(
    context,
    'plantilla',
    'Otro bróker (plantilla)',
    jsonEncode(paraGuardar),
  );
  if (!guardado.startsWith('true')) {
    return; // el usuario ha elegido no guardar
  }

  // El resumen lo enseña mostrarResumenBolsa al terminar todos los
  // documentos.
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
