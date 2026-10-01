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
// Custom Action: descargarPlantillaFifo
// Lee la plantilla CSV desde Firestore (app_config/plantilla_fifo) y:
//   - En iPad/dispositivo real: la guarda como archivo y abre el panel
//     nativo de compartir/guardar.
//   - En web (incluido el modo Test de FlutterFlow): muestra la
//     plantilla con un botón "Copiar" (el navegador no permite escribir
//     archivos en disco).
//
// PARÁMETROS:
//   context (BuildContext)
//
// Include BuildContext: ON
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> descargarPlantillaFifo(BuildContext context) async {
  String contenido = '';
  String nombreArchivo = 'plantilla_operaciones_fifo.csv';
  String errorLectura = '';
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('plantilla_fifo')
        .get();
    if (doc.exists) {
      contenido = doc.data()?['contenido_csv'] as String? ?? '';
      nombreArchivo = doc.data()?['nombre_archivo'] as String? ?? nombreArchivo;
    } else {
      errorLectura = 'El documento app_config/plantilla_fifo no existe.';
    }
  } catch (e) {
    errorLectura = e.toString();
  }

  if (contenido.trim().isEmpty) {
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
            _tituloVentana('No se ha podido cargar la plantilla'),
            const SizedBox(height: 8),
            _parrafo(errorLectura.isEmpty
                ? 'El campo contenido_csv del documento '
                    'app_config/plantilla_fifo está vacío o solo tiene '
                    'espacios en blanco. Revísalo en Firebase Console.'
                : errorLectura),
          ],
        ),
        botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
      ),
    );
    return;
  }

  Future<void> mostrarConCopiar() async {
    await showDialog(
      context: context,
      builder: (ctx) => _ventanaApp(
        titulo: 'Plantilla de operaciones',
        icono: Icons.table_chart_outlined,
        ancho: 520,
        onCerrar: () => Navigator.pop(ctx),
        cuerpo: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tituloVentana('Copia la plantilla'),
            const SizedBox(height: 6),
            _parrafo('Copia este contenido y pégalo en un archivo nuevo de '
                'Excel o Google Sheets. Rellena tus operaciones y guárdalo '
                'como CSV.'),
            const SizedBox(height: 12),
            Container(
              height: 260,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorde),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  contenido,
                  style: const TextStyle(fontSize: 12, color: _kTexto),
                ),
              ),
            ),
          ],
        ),
        botones: [
          _botonPrimario('Copiar al portapapeles', () async {
            await Clipboard.setData(ClipboardData(text: contenido));
            Navigator.pop(ctx);
          }),
        ],
      ),
    );
  }

  if (kIsWeb) {
    await mostrarConCopiar();
    return;
  }

  try {
    final directorio = await getTemporaryDirectory();
    final archivo = File('${directorio.path}/$nombreArchivo');
    await archivo.writeAsString(contenido);
    await Share.shareXFiles(
      [XFile(archivo.path)],
      text: 'Plantilla de operaciones para MiRenta Asistente',
    );
  } catch (e) {
    await mostrarConCopiar();
  }
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
