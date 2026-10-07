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
// Custom Action: procesarInformeDegiro
// Flujo completo del Informe Anual (PDF) de DEGIRO: calcula, pregunta si las
// salidas detectadas fueron ventas o traspasos, pide las posiciones previas
// si hacen falta, enseña el resumen y guarda a través de
// guardarResultadoBroker (que consolida con el resto de brókeres).
//
// PARÁMETROS:
//   context (BuildContext)
//   archivoPdf (FFUploadedFile) -> lo devuelve elegirArchivoPdf()
//   anioEjercicio (int)
//
// DEVUELVE: 'true|ganancias|perdidas|gananciasCortas|perdidasCortas' o 'false|0|0|0|0'
//
// Include BuildContext: ON
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/uploaded_file.dart';
import '/custom_code/actions/index.dart';

Future<String> procesarInformeDegiro(
  BuildContext context,
  FFUploadedFile archivoPdf,
  int anioEjercicio,
) async {
  final bytes = archivoPdf.bytes;
  if (bytes == null || bytes.isEmpty) return 'false|0|0|0|0';

  double aNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void cargando(String texto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ventanaCargando(texto),
    );
  }

  // ---------- 1. Primera llamada ----------
  cargando('Leyendo tu informe de DEGIRO...');
  String resultadoJson =
      await calcularGananciasDegiro(archivoPdf, anioEjercicio, '[]', '[]');
  if (context.mounted) Navigator.pop(context);

  Map<String, dynamic> data;
  try {
    data = jsonDecode(resultadoJson) as Map<String, dynamic>;
  } catch (e) {
    return 'false|0|0|0|0';
  }

  if (data['ok'] != true) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => _ventanaApp(
          titulo: 'DEGIRO',
          icono: Icons.error_outline,
          ancho: 440,
          onCerrar: () => Navigator.pop(ctx),
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('No se ha podido leer el informe'),
              const SizedBox(height: 8),
              _parrafo(data['mensaje']?.toString() ?? 'Error desconocido.'),
            ],
          ),
          botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
        ),
      );
    }
    return 'false|0|0|0|0';
  }

  // ---------- 1b. ¿Venta o traspaso a otro bróker? ----------
  // DEGIRO anota los traspasos salientes como si fueran ventas. Para Hacienda
  // un traspaso no es una transmisión: no hay ganancia ni pérdida y los
  // valores conservan su fecha y coste originales. Solo el usuario sabe cuál
  // fue, así que se le pregunta.
  String confirmadosJson = '[]';
  final detectados = (data['traspasos_detectados'] as List?) ?? [];
  if (detectados.isNotEmpty && context.mounted) {
    final Map<String, bool> esTraspaso = {
      for (final t in detectados) t['isin'].toString(): true,
    };
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => _ventanaApp(
          titulo: 'DEGIRO',
          icono: Icons.swap_horiz,
          ancho: 520,
          cuerpo: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tituloVentana('¿Venta o traspaso?'),
              const SizedBox(height: 6),
              _parrafo(
                  'DEGIRO anota igual una venta que un traspaso a otro bróker. '
                  'Si fue un traspaso, no tributa: los valores mantienen tu '
                  'fecha y precio de compra originales.'),
              const SizedBox(height: 14),
              ...detectados.map((t) {
                final isin = t['isin'].toString();
                final cant = _numEs((t['cantidad'] as num).toDouble(), dec: 0);
                final f = t['fecha'].toString().split('-');
                final fecha =
                    f.length == 3 ? '${f[2]}/${f[1]}/${f[0]}' : t['fecha'];
                Widget opcion(String texto, bool valor) {
                  final sel = esTraspaso[isin] == valor;
                  return InkWell(
                    onTap: () => setState(() => esTraspaso[isin] = valor),
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _tarjeta(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t['producto']}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTexto)),
                      const SizedBox(height: 2),
                      Text('$cant acciones salen de DEGIRO el $fecha',
                          style: const TextStyle(
                              fontSize: 12.5, color: _kTextoSec)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: opcion('Las traspasé', true)),
                          const SizedBox(width: 10),
                          Expanded(child: opcion('Las vendí', false)),
                        ],
                      ),
                    ],
                  )),
                );
              }),
            ],
          ),
          botones: [_botonPrimario('Continuar', () => Navigator.pop(ctx))],
        ),
      ),
    );

    final confirmados =
        esTraspaso.entries.where((e) => e.value).map((e) => e.key).toList();
    if (confirmados.isNotEmpty) {
      confirmadosJson = jsonEncode(confirmados);
      cargando('Recalculando sin los traspasos...');
      resultadoJson = await calcularGananciasDegiro(
          archivoPdf, anioEjercicio, '[]', confirmadosJson);
      if (context.mounted) Navigator.pop(context);
      try {
        data = jsonDecode(resultadoJson) as Map<String, dynamic>;
      } catch (e) {
        return 'false|0|0|0|0';
      }

      // Guardar los lotes que salieron, por ISIN: el bróker de destino los
      // necesita como posición previa con su fecha y coste ORIGINALES.
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> guardados = {};
      try {
        guardados = Map<String, dynamic>.from(jsonDecode(
            prefs.getString('answer_traspasos_salientes_json') ?? '{}'));
      } catch (_) {}
      for (final t in ((data['traspasos_salientes'] as List?) ?? [])) {
        guardados[t['isin'].toString()] = t;
      }
      await prefs.setString(
          'answer_traspasos_salientes_json', jsonEncode(guardados));
    }
  }

  // ---------- 2. Posiciones previas, si las pide ----------
  final pendientes = (data['simbolos_pendientes'] as List?) ?? [];
  if (pendientes.isNotEmpty && context.mounted) {
    final previasJson =
        await pedirPosicionesPrevias(context, resultadoJson, '[]');
    cargando('Recalculando con tus posiciones...');
    resultadoJson = await calcularGananciasDegiro(
        archivoPdf, anioEjercicio, previasJson, confirmadosJson);
    if (context.mounted) Navigator.pop(context);
    try {
      data = jsonDecode(resultadoJson) as Map<String, dynamic>;
    } catch (e) {
      return 'false|0|0|0|0';
    }
  }

  final avisos = (data['avisos'] as List?) ?? [];
  final verificacion = (data['verificacion'] as Map?) ?? {};
  final cuadra = verificacion['cuadra'] == true;
  // ---------- 3. Verificación ----------
  // El resumen lo enseña mostrarResumenBolsa al terminar todos los
  // documentos; aquí solo se avisa si el cálculo no cuadra con DEGIRO.
  if (!cuadra && context.mounted) {
    await showDialog(
      context: context,
      builder: (ctx) => _ventanaApp(
        titulo: 'DEGIRO',
        icono: Icons.warning_amber_rounded,
        ancho: 460,
        cuerpo: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloVentana('El resultado no cuadra con DEGIRO'),
            const SizedBox(height: 8),
            _parrafo(
                'Calculado: ${_eur(aNum(verificacion['neto_calculado']))}. '
                'Esperado según el informe: ${_eur(aNum(verificacion['esperado']))}. '
                'Diferencia: ${_eur(aNum(verificacion['diferencia']))}. '
                'Revisa el detalle antes de usar estas cifras.'),
            if (avisos.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...avisos.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _avisoCaja(a.toString()),
                  )),
            ],
          ],
        ),
        botones: [_botonPrimario('Continuar', () => Navigator.pop(ctx))],
      ),
    );
  }

  // ---------- 4. Guardar ----------
  // Todo el guardado pasa por guardarResultadoBroker, que consolida con el
  // resto de brókeres y aplica la regla de los 2 meses entre todos.
  if (!context.mounted) return 'false|0|0|0|0';
  final guardado = await guardarResultadoBroker(
    context,
    data['id_broker']?.toString() ?? 'degiro',
    'DEGIRO',
    resultadoJson,
  );
  if (!guardado.startsWith('true')) return 'false|0|0|0|0';

  final piezas = guardado.split('|');
  double pieza(int i) =>
      piezas.length > i ? (double.tryParse(piezas[i]) ?? 0.0) : 0.0;
  return 'true|${pieza(1)}|${pieza(2)}|${pieza(3)}|${pieza(4)}';
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

String _eur(double v) => '${_numEs(v)} €';

// ============================================================
// Números en formato español: punto de miles y coma decimal
// (75.891,42). Mismo bloque en todas las acciones que muestran o leen
// importes, para que la app sea coherente en todas sus pantallas.
// ============================================================

/// 75891.42 -> "75.891,42"; con dec: 0 -> "75.891".
String _numEs(double v, {int dec = 2}) {
  final negativo = v < 0;
  final s = v.abs().toStringAsFixed(dec);
  final partes = s.split('.');
  final ent =
      partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  final txt = dec > 0 ? '$ent,${partes[1]}' : ent;
  return negativo ? '-$txt' : txt;
}

/// Lee un número escrito de cualquier forma razonable:
/// "75.891,42", "75891,42", "75891.42", "75.891", "1,5".
/// Con punto y coma, el que va último es el decimal. Con solo puntos, si
/// están agrupados de tres en tres son de miles. Devuelve null si no hay
/// número.
double? _leerNumeroEs(String bruto) {
  var t =
      bruto.trim().replaceAll(' ', '').replaceAll(' ', '').replaceAll('€', '');
  if (t.isEmpty) return null;
  final hayPunto = t.contains('.');
  final hayComa = t.contains(',');
  if (hayPunto && hayComa) {
    if (t.lastIndexOf(',') > t.lastIndexOf('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
  } else if (hayComa) {
    t = t.replaceAll(',', '.');
  } else if (hayPunto && RegExp(r'^-?\d{1,3}(\.\d{3})+$').hasMatch(t)) {
    t = t.replaceAll('.', '');
  }
  return double.tryParse(t);
}
