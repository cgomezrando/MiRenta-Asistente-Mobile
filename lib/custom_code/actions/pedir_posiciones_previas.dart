// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/services.dart';

// ============================================================
// Custom Action: pedirPosicionesPrevias
// Pide fecha, cantidad, precio y moneda de la posicion previa de cada
// simbolo que calcularGananciasIBKR ha marcado como pendiente.
// Devuelve el JSON de posiciones previas para la siguiente llamada.
//
// PARAMETROS:
//   context (BuildContext)
//   resultadoIbkrJson (String)
//   posicionesPreviasJsonActual (String)  -> '[]' la primera vez
// DEVUELVE: String JSON (lista)
//
// Include BuildContext: ON
// Paquetes necesarios: ninguno nuevo (solo dart:convert)
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> pedirPosicionesPrevias(
  BuildContext context,
  String resultadoIbkrJson,
  String posicionesPreviasJsonActual,
) async {
  // Colores de la estética común (definidos al final del archivo).
  const azul = _kAzul;
  const textoSec = _kTextoSec;
  const textoPrin = _kTexto;
  const rojo = _kRojo;

  // ---- parseo tolerante a formato espanol (1.234,56 / 1234.56 / 1234,56)
  double? aNumero(String bruto) => _leerNumeroEs(bruto);

  String esp(double v, int dec) => _numEs(v, dec: dec);

  // ---- entrada
  Map<String, dynamic> entrada;
  try {
    entrada = jsonDecode(resultadoIbkrJson) as Map<String, dynamic>;
  } catch (e) {
    return posicionesPreviasJsonActual.isEmpty
        ? '[]'
        : posicionesPreviasJsonActual;
  }

  // acepta las dos claves posibles del backend
  final pendientes = (entrada['simbolos_pendientes'] as List?) ??
      (entrada['simbolos_con_posicion_previa_pendiente'] as List?) ??
      const [];

  List<dynamic> yaAportadas = [];
  try {
    yaAportadas = jsonDecode(
      posicionesPreviasJsonActual.isEmpty ? '[]' : posicionesPreviasJsonActual,
    ) as List<dynamic>;
  } catch (_) {}

  // ---- normalizacion de las filas
  final List<Map<String, dynamic>> filas = [];
  for (final p in pendientes) {
    String sym;
    double necesaria;
    if (p is Map) {
      sym = (p['simbolo'] ?? p['symbol'] ?? '').toString();
      final raw = p['posicion_previa_necesaria'] ?? p['cantidad'] ?? 0;
      necesaria =
          raw is num ? raw.toDouble() : (aNumero(raw.toString()) ?? 0.0);
    } else {
      sym = p.toString();
      necesaria = 0.0;
    }
    if (sym.isEmpty) continue;
    filas.add({
      'simbolo': sym,
      'necesaria': necesaria,
      'isin': (p is Map ? (p['isin'] ?? '') : '').toString(),
      'traspaso': p is Map ? p['traspaso_entrada'] : null,
    });
  }

  if (filas.isEmpty) {
    return posicionesPreviasJsonActual.isEmpty
        ? '[]'
        : posicionesPreviasJsonActual;
  }

  // ---- estado
  final Map<String, TextEditingController> cantidadCtrls = {};
  final Map<String, TextEditingController> precioCtrls = {};
  final Map<String, DateTime?> fechas = {};
  final Map<String, String> monedas = {};

  for (final f in filas) {
    final sym = f['simbolo'] as String;
    final n = (f['necesaria'] as double).abs();
    cantidadCtrls[sym] =
        TextEditingController(text: n % 1 == 0 ? esp(n, 0) : esp(n, 4));
    precioCtrls[sym] = TextEditingController();
    fechas[sym] = null;
    monedas[sym] = 'USD';
  }

  // Si el usuario ya subió el informe del bróker de ORIGEN (p. ej. DEGIRO) y
  // confirmó el traspaso, ahí están la fecha y el coste originales de esas
  // acciones: se proponen directamente en vez de pedírselos a mano.
  final Map<String, List> lotesOrigen = {};
  final Map<String, bool> usarTraspaso = {};
  try {
    final prefs = await SharedPreferences.getInstance();
    final guardados = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_traspasos_salientes_json') ?? '{}'));
    for (final f in filas) {
      final isin = f['isin'] as String;
      if (isin.isNotEmpty && guardados[isin] is Map) {
        final lotes = (guardados[isin]['lotes'] as List?) ?? [];
        if (lotes.isNotEmpty) {
          lotesOrigen[f['simbolo'] as String] = lotes;
          usarTraspaso[f['simbolo'] as String] = true;
        }
      }
    }
  } catch (_) {}

  String fmtFecha(String iso) {
    final t = iso.split('-');
    return t.length == 3 ? '${t[2]}/${t[1]}/${t[0]}' : iso;
  }

  bool cancelado = false;

  bool filaCompleta(String sym) {
    if (usarTraspaso[sym] == true) return true;
    final c = aNumero(cantidadCtrls[sym]!.text);
    final pr = aNumero(precioCtrls[sym]!.text);
    return c != null && c > 0 && pr != null && pr > 0 && fechas[sym] != null;
  }

  InputDecoration deco(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        labelStyle: TextStyle(color: textoSec, fontSize: 13),
        floatingLabelStyle: TextStyle(color: azul, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: azul.withOpacity(0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: azul, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: azul.withOpacity(0.55)),
        ),
      );

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        final incompletas =
            filas.where((f) => !filaCompleta(f['simbolo'] as String)).length;
        final todoOk = incompletas == 0;

        Widget tarjeta(String sym, double necesaria) {
          final fila = filas.firstWhere((x) => x['simbolo'] == sym);
          final traspaso = fila['traspaso'];

          // Datos traídos del bróker de origen: se enseñan y se usan tal cual.
          if (usarTraspaso[sym] == true && lotesOrigen[sym] != null) {
            final lotes = lotesOrigen[sym]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: azul.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sym,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textoPrin)),
                  const SizedBox(height: 4),
                  Text(
                    'Datos de tu compra original, tomados del informe del bróker de origen. El traspaso no tributa: se conserva la fecha y el coste de compra.',
                    style: TextStyle(
                        fontSize: 11.5, color: textoSec, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  ...lotes.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${fmtFecha(l['fecha'].toString())}  ·  ${esp((l['cantidad'] as num).toDouble(), 0)} acciones  ·  ${esp((l['precio'] as num).toDouble(), 4)} €/acción',
                          style: TextStyle(fontSize: 13, color: textoPrin),
                        ),
                      )),
                  const SizedBox(height: 6),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => usarTraspaso[sym] = false),
                    child: Text('No son correctos, prefiero escribirlos',
                        style: TextStyle(color: azul, fontSize: 12.5)),
                  ),
                ],
              ),
            );
          }

          final esCorto = necesaria < 0;
          final cant = aNumero(cantidadCtrls[sym]!.text);
          final pr = aNumero(precioCtrls[sym]!.text);
          final coste = (cant != null && pr != null) ? cant * pr : null;

          final falta = <String>[];
          if (cant == null || cant <= 0) falta.add('cantidad');
          if (pr == null || pr <= 0) falta.add('precio');
          if (fechas[sym] == null) falta.add('fecha');

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: falta.isEmpty
                    ? azul.withOpacity(0.18)
                    : rojo.withOpacity(0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sym,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textoPrin,
                      ),
                    ),
                    if (esCorto) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: rojo.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CORTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: rojo,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cantidad estimada: ${necesaria.abs() % 1 == 0 ? esp(necesaria.abs(), 0) : esp(necesaria.abs(), 4)} (ajustala si no es exacta)',
                  style: TextStyle(fontSize: 11.5, color: textoSec),
                ),
                if (traspaso is Map) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: azul.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Llegaron por traspaso el ${fmtFecha(traspaso['fecha'].toString())} desde otra entidad. Pon la fecha y el precio de tu compra ORIGINAL, no el valor del día del traspaso: para Hacienda el traspaso no es una venta.',
                      style: TextStyle(
                          fontSize: 11.5, color: textoPrin, height: 1.35),
                    ),
                  ),
                ],
                if (lotesOrigen[sym] != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => usarTraspaso[sym] = true),
                    child: Text('Usar los datos del bróker de origen',
                        style: TextStyle(color: azul, fontSize: 12.5)),
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cantidadCtrls[sym],
                        inputFormatters: [_FormatoMilesEs(decimales: 4)],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: textoPrin, fontSize: 14),
                        cursorColor: azul,
                        onChanged: (_) => setState(() {}),
                        decoration: deco('Cantidad'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: precioCtrls[sym],
                        inputFormatters: [_FormatoMilesEs(decimales: 4)],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: TextStyle(color: textoPrin, fontSize: 14),
                        cursorColor: azul,
                        onChanged: (_) => setState(() {}),
                        decoration: deco('Precio (${monedas[sym]})'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final elegida = await showDatePicker(
                            context: ctx,
                            initialDate: fechas[sym] ?? DateTime(2024, 1, 1),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
                            helpText: 'Fecha de compra de $sym',
                          );
                          if (elegida != null) {
                            setState(() => fechas[sym] = elegida);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: fechas[sym] == null
                                  ? rojo.withOpacity(0.55)
                                  : azul.withOpacity(0.55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 15, color: textoSec),
                              const SizedBox(width: 8),
                              Text(
                                fechas[sym] == null
                                    ? 'Fecha de compra'
                                    : '${fechas[sym]!.day.toString().padLeft(2, '0')}/${fechas[sym]!.month.toString().padLeft(2, '0')}/${fechas[sym]!.year}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: fechas[sym] == null
                                      ? textoSec
                                      : textoPrin,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: azul.withOpacity(0.55)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: monedas[sym],
                          isDense: true,
                          dropdownColor: Colors.white,
                          iconEnabledColor: azul,
                          style: TextStyle(color: textoPrin, fontSize: 14),
                          items: [
                            DropdownMenuItem(
                              value: 'USD',
                              child: Text('USD',
                                  style: TextStyle(
                                      color: textoPrin, fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'EUR',
                              child: Text('EUR',
                                  style: TextStyle(
                                      color: textoPrin, fontSize: 14)),
                            ),
                          ],
                          onChanged: (v) => setState(() => monedas[sym] = v!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (falta.isNotEmpty)
                  Text(
                    'Falta ${falta.join(', ')}',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: rojo,
                        fontWeight: FontWeight.w600),
                  )
                else if (coste != null)
                  Text(
                    'Coste de adquisicion: ${esp(coste, 2)} ${monedas[sym]}',
                    style: TextStyle(fontSize: 11.5, color: textoSec),
                  ),
              ],
            ),
          );
        }

        return _ventanaApp(
          titulo: 'Posiciones anteriores',
          icono: Icons.inventory_2_outlined,
          ancho: 520,
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('Posiciones anteriores a este periodo'),
              const SizedBox(height: 6),
              _parrafo('Estos ${filas.length} valores ya los tenías antes del '
                  'periodo del archivo cargado. Indica cuándo los compraste '
                  'y a qué precio: sin estos datos el resultado sería '
                  'incorrecto.'),
              const SizedBox(height: 14),
              ...filas.map((f) =>
                  tarjeta(f['simbolo'] as String, f['necesaria'] as double)),
            ],
          ),
          pie: todoOk
              ? null
              : Text(
                  incompletas == 1
                      ? 'Falta completar 1 valor'
                      : 'Faltan completar $incompletas valores',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: _kRojo,
                      fontWeight: FontWeight.w600),
                ),
          botones: [
            _botonSecundario('Cancelar', () {
              cancelado = true;
              Navigator.pop(ctx);
            }),
            _botonPrimario(
                'Continuar', todoOk ? () => Navigator.pop(ctx) : null),
          ],
        );
      });
    },
  );

  // ---- salida
  String salida;
  if (cancelado) {
    salida = jsonEncode(yaAportadas);
  } else {
    final List<Map<String, dynamic>> deOrigen = [];
    for (final f in filas) {
      final sym = f['simbolo'] as String;
      if (usarTraspaso[sym] == true && lotesOrigen[sym] != null) {
        for (final l in lotesOrigen[sym]!) {
          deOrigen.add({
            'simbolo': sym,
            'tipo_posicion': 'largo',
            'fecha': l['fecha'],
            'cantidad': l['cantidad'],
            'precio': l['precio'],
            'moneda': l['moneda'] ?? 'EUR',
            'comision': l['comision'] ?? 0.0,
          });
        }
      }
    }
    final nuevas =
        filas.where((f) => usarTraspaso[f['simbolo']] != true).map((f) {
      final sym = f['simbolo'] as String;
      final necesaria = f['necesaria'] as double;
      final cantidad = aNumero(cantidadCtrls[sym]!.text) ?? necesaria.abs();
      final precio = aNumero(precioCtrls[sym]!.text) ?? 0.0;
      final fecha = fechas[sym] ?? DateTime(2020, 1, 1);
      return {
        'simbolo': sym,
        'tipo_posicion': necesaria < 0 ? 'corto' : 'largo',
        'fecha':
            '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        'cantidad': cantidad.abs(),
        'precio': precio,
        'moneda': monedas[sym],
        'comision': 0.0,
      };
    }).toList();
    salida = jsonEncode([...yaAportadas, ...deOrigen, ...nuevas]);
  }

  for (final c in cantidadCtrls.values) {
    c.dispose();
  }
  for (final c in precioCtrls.values) {
    c.dispose();
  }

  return salida;
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
