// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/services.dart';

// ============================================================
// Custom Action: gestionarPerdidasPendientes
// Una sola pantalla con los cuatro ejercicios anteriores a la vista, en vez
// de cuatro preguntas seguidas.
//
// Las perdidas patrimoniales no compensadas se arrastran durante los cuatro
// ejercicios siguientes y se compensan empezando por las mas antiguas, asi
// que hace falta el año de cada una y no un total. Las de hace cuatro años
// son las que caducan con esta declaracion.
//
// Guarda en answer_m06_perdidas_pendientes_<anio>, que es lo que suma
// calcularDeclaracion.
//
// PARAMETROS:
//   context (BuildContext)
//   anioEjercicio (int) -> el ejercicio que se declara; los cuatro años se
//       calculan a partir de el, asi no hay que tocar nada cada año.
//
// DEVUELVE: el total introducido, como texto en formato español.
//
// Include BuildContext: ON
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

Future<String> gestionarPerdidasPendientes(
  BuildContext context,
  int anioEjercicio,
) async {
  // Colores de la estética común (definidos al final del archivo).
  const azul = _kAzul;
  const textoSec = _kTextoSec;
  const textoPrin = _kTexto;

  final anios = [
    anioEjercicio - 4,
    anioEjercicio - 3,
    anioEjercicio - 2,
    anioEjercicio - 1,
  ];

  double aNumero(String bruto) => _leerNumeroEs(bruto) ?? 0.0;

  String esp(double v) => _numEs(v);

  final prefs = await SharedPreferences.getInstance();
  final Map<int, TextEditingController> campos = {};
  for (final a in anios) {
    final guardado = prefs.getString('answer_m06_perdidas_pendientes_$a') ?? '';
    final valor = _leerNumeroEs(guardado);
    campos[a] = TextEditingController(
        text: (valor == null || valor == 0) ? '' : _numEs(valor));
  }

  bool confirmado = false;
  if (!context.mounted) return '0,00';

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        double total = 0.0;
        for (final a in anios) {
          total += aNumero(campos[a]!.text);
        }

        return _ventanaApp(
          titulo: 'Módulo M06',
          icono: Icons.history,
          ancho: 480,
          cuerpo: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tituloVentana('Pérdidas pendientes de compensar'),
              const SizedBox(height: 6),
              _parrafo('Indica de qué año viene cada pérdida. Se compensan '
                  'empezando por las más antiguas, así que el año importa. '
                  'Deja en blanco los años en los que no tengas nada.'),
              const SizedBox(height: 18),
              ...anios.map((a) {
                final caduca = a == anios.first;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 66,
                            child: Text('$a',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textoPrin)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: campos[a],
                              inputFormatters: [_FormatoMilesEs()],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                  color: textoPrin, fontSize: 14),
                              cursorColor: azul,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: '0,00',
                                hintStyle: const TextStyle(
                                    color: textoSec, fontSize: 14),
                                suffixText: '€',
                                suffixStyle: const TextStyle(color: textoSec),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _kBorde),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: azul, width: 1.6),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _kBorde),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (caduca)
                        Padding(
                          padding: const EdgeInsets.only(left: 66, top: 4),
                          child: Text(
                            'Último año para compensarlas: si no las usas '
                            'en esta declaración, se pierden.',
                            style: TextStyle(
                                fontSize: 11.5, color: Color(0xFFBA7517)),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              _tarjeta(
                Text('Total pendiente: ${esp(total)} €',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: azul)),
                fondo: azul.withOpacity(0.06),
                borde: azul.withOpacity(0.15),
              ),
            ],
          ),
          botones: [
            _botonSecundario('Cancelar', () => Navigator.pop(ctx)),
            _botonPrimario('Guardar', () {
              confirmado = true;
              Navigator.pop(ctx);
            }),
          ],
        );
      });
    },
  );

  double total = 0.0;
  if (confirmado) {
    for (final a in anios) {
      final v = aNumero(campos[a]!.text);
      total += v;
      await prefs.setString('answer_m06_perdidas_pendientes_$a', esp(v));
    }
  }

  for (final c in campos.values) {
    c.dispose();
  }

  return esp(total);
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

/// Pone el punto de miles mientras se escribe ("75891" -> "75.891") y
/// admite coma decimal. Un punto tecleado se toma como coma: los de miles
/// los pone la app. Al pegar "75891.42" se entiende como decimal.
class _FormatoMilesEs extends TextInputFormatter {
  _FormatoMilesEs({this.decimales = 2});
  final int decimales;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue viejo, TextEditingValue nuevo) {
    var t = nuevo.text;
    var cursor = nuevo.selection.baseOffset;
    if (cursor < 0 || cursor > t.length) cursor = t.length;

    if (t.length == viejo.text.length + 1 &&
        cursor > 0 &&
        t[cursor - 1] == '.') {
      // Punto recién tecleado: es la coma decimal.
      t = '${t.substring(0, cursor - 1)},${t.substring(cursor)}';
    } else if (t.length > viejo.text.length + 1 &&
        !t.contains(',') &&
        '.'.allMatches(t).length == 1 &&
        !RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t.trim())) {
      // Texto pegado con punto decimal ("75891.42").
      t = t.replaceAll('.', ',');
    }

    // Solo cuentan dígitos y la coma; los puntos de miles se recalculan.
    final antes = t
        .substring(0, cursor > t.length ? t.length : cursor)
        .replaceAll(RegExp(r'[^0-9,]'), '')
        .length;
    t = t.replaceAll(RegExp(r'[^0-9,]'), '');
    if (t.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final coma = t.indexOf(',');
    var ent = coma >= 0 ? t.substring(0, coma) : t;
    var dec = coma >= 0 ? t.substring(coma + 1).replaceAll(',', '') : '';
    if (dec.length > decimales) dec = dec.substring(0, decimales);
    ent = ent.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final entFmt =
        ent.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    final res = (coma >= 0 && decimales > 0) ? '$entFmt,$dec' : entFmt;

    // Recolocar el cursor tras el mismo número de dígitos que antes.
    var pos = 0, vistos = 0;
    while (pos < res.length && vistos < antes) {
      if (res[pos] != '.') vistos++;
      pos++;
    }
    return TextEditingValue(
        text: res, selection: TextSelection.collapsed(offset: pos));
  }
}
