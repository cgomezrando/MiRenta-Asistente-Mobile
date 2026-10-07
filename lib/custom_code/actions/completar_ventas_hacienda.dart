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
// Custom Action: completarVentasHacienda
// Ventas de acciones que constan en los datos fiscales de la AEAT (las
// comunican los bancos españoles: Bankinter, ING, Santander...). Hacienda
// sabe la fecha, el valor, el importe y los gastos, pero no el ISIN, el
// número de acciones ni lo que costaron. Esta pantalla los pide, calcula
// con el mismo motor que IBKR y DEGIRO (FIFO y regla de los dos meses entre
// brókeres) y guarda el resultado con guardarResultadoBroker.
//
// Lee las ventas que deja procesarDatosFiscales en
// answer_ventas_hacienda_json y recuerda lo que el usuario escribió en
// answer_ventas_hacienda_datos_json (por código de operación).
//
// PARÁMETROS: context (BuildContext), anioEjercicio (int)
// DEVUELVE: 'true|n' (n = ventas calculadas) o 'false|0'
// Include BuildContext: ON. Return Value: ON -> String.
// Paquetes: ninguno nuevo.
// ============================================================

import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> completarVentasHacienda(
  BuildContext context,
  int anioEjercicio,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';
  final prefs = await SharedPreferences.getInstance();

  List ventas = [];
  try {
    ventas = jsonDecode(prefs.getString('answer_ventas_hacienda_json') ?? '[]')
        as List;
  } catch (_) {}
  if (ventas.isEmpty || !context.mounted) return 'false|0';

  double aNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return _leerNumeroEs(v.toString()) ?? 0.0;
  }

  String fechaEs(String iso) {
    final t = iso.split('-');
    return t.length == 3 ? '${t[2]}/${t[1]}/${t[0]}' : iso;
  }

  String isoDe(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------- Sugerencia de ISIN a partir de los brókeres ya subidos ----------
  const sufijos = {
    'SA',
    'S',
    'A',
    'INC',
    'CORP',
    'CORPORATION',
    'NV',
    'N',
    'V',
    'PLC',
    'AG',
    'SE',
    'LTD',
    'CO',
    'THE',
    'HOLDING',
    'HOLDINGS',
    'GROUP',
    'NY',
    'REGISTERED',
    'SHS',
    'REG',
    'CLASE',
    'CL'
  };
  String clave(String nombre) {
    final palabras = nombre
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .split(' ')
        .where((p) => p.isNotEmpty && !sufijos.contains(p))
        .toList();
    return palabras.isEmpty ? '' : palabras.first;
  }

  final Map<String, String> isinPorNombre = {}; // isin -> nombre
  try {
    final cartera = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_cartera_fiscal_json') ?? '{}'));
    for (final e in cartera.values) {
      if (e is! Map || e['huella'] is! Map) continue;
      final h = e['huella'] as Map;
      for (final x in [
        ...(h['compras'] as List? ?? []),
        ...(h['ventas'] as List? ?? [])
      ]) {
        final isin = (x['isin'] ?? '').toString();
        if (isin.length == 12) {
          isinPorNombre[isin] = (x['nombre'] ?? x['simbolo'] ?? '').toString();
        }
      }
    }
  } catch (_) {}

  String sugerirIsin(String emisor) {
    final k = clave(emisor);
    if (k.length < 4) return '';
    final candidatos = isinPorNombre.entries
        .where((e) {
          final k2 = clave(e.value);
          if (k2.length < 4) return false;
          return k2.startsWith(k) || k.startsWith(k2);
        })
        .map((e) => e.key)
        .toList();
    if (candidatos.isEmpty) return '';
    // Los bancos españoles suelen operar en la bolsa española: se prefiere
    // el ISIN no estadounidense si el mismo valor tiene varios.
    candidatos.sort((a, b) =>
        (a.startsWith('US') ? 1 : 0).compareTo(b.startsWith('US') ? 1 : 0));
    return candidatos.first;
  }

  // ---------- Estado de la pantalla (recupera lo escrito otras veces) ----------
  Map<String, dynamic> guardados = {};
  try {
    guardados = Map<String, dynamic>.from(jsonDecode(
        prefs.getString('answer_ventas_hacienda_datos_json') ?? '{}'));
  } catch (_) {}

  final filas = <Map<String, dynamic>>[];
  for (var i = 0; i < ventas.length; i++) {
    final v = Map<String, dynamic>.from(ventas[i] as Map);
    final codigo = (v['codigo'] ?? 'V${i + 1}').toString();
    final g = (guardados[codigo] is Map)
        ? Map<String, dynamic>.from(guardados[codigo])
        : <String, dynamic>{};
    final isinInicial =
        (g['isin'] ?? sugerirIsin((v['emisor'] ?? '').toString())).toString();
    filas.add({
      'codigo': codigo,
      'venta': v,
      'isin': TextEditingController(text: isinInicial),
      'isin_sugerido': g['isin'] == null && isinInicial.isNotEmpty,
      'cantidad': TextEditingController(
          text:
              g['cantidad'] != null ? _numEs(aNum(g['cantidad']), dec: 0) : ''),
      'coste': TextEditingController(
          text:
              g['coste_compra'] != null ? _numEs(aNum(g['coste_compra'])) : ''),
      'fecha': g['fecha_compra'] != null
          ? DateTime.tryParse(g['fecha_compra'].toString())
          : null,
      'incluida': g['incluida'] == true,
      'recompra': g['recompra_externa'] == true,
    });
  }

  bool filaCompleta(Map f) {
    if (f['incluida'] == true) return true;
    final isin = (f['isin'] as TextEditingController).text.trim().toUpperCase();
    final cant = _leerNumeroEs((f['cantidad'] as TextEditingController).text);
    final coste = _leerNumeroEs((f['coste'] as TextEditingController).text);
    return _isinValido(isin) &&
        cant != null &&
        cant > 0 &&
        coste != null &&
        coste >= 0 &&
        f['fecha'] != null;
  }

  double? resultadoFila(Map f) {
    final coste = _leerNumeroEs((f['coste'] as TextEditingController).text);
    if (coste == null) return null;
    final v = f['venta'] as Map;
    return aNum(v['importe_venta']) - aNum(v['gastos']) - coste;
  }

  InputDecoration deco(String etiqueta, {String? error, String? sufijo}) =>
      InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: _kTextoSec, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: _kAzul, fontSize: 13),
        errorText: error,
        suffixText: sufijo,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kAzul, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorde),
        ),
      );

  bool confirmado = false;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final pendientes = filas.where((f) => !filaCompleta(f)).length;

      Widget tarjetaVenta(Map<String, dynamic> f) {
        final v = f['venta'] as Map;
        final incluida = f['incluida'] == true;
        final isinTxt =
            (f['isin'] as TextEditingController).text.trim().toUpperCase();
        final isinMal = isinTxt.isNotEmpty && !_isinValido(isinTxt);
        final res = resultadoFila(f);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _tarjeta(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${v['emisor'] ?? 'Valor'}',
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _kTexto)),
                const SizedBox(height: 2),
                Text(
                  '${v['broker'] ?? ''} · vendida el '
                  '${fechaEs((v['fecha'] ?? '').toString())} · '
                  '${_eur(aNum(v['importe_venta']))}'
                  '${aNum(v['gastos']) > 0 ? ' (gastos ${_eur(aNum(v['gastos']))})' : ''}',
                  style: const TextStyle(fontSize: 12.5, color: _kTextoSec),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => f['incluida'] = !incluida),
                  child: Row(
                    children: [
                      Checkbox(
                        value: incluida,
                        activeColor: _kAzul,
                        visualDensity: VisualDensity.compact,
                        onChanged: (x) =>
                            setState(() => f['incluida'] = x == true),
                      ),
                      const Expanded(
                        child: Text(
                            'Ya la he incluido en otro documento (plantilla)',
                            style: TextStyle(fontSize: 12.5, color: _kTexto)),
                      ),
                    ],
                  ),
                ),
                if (!incluida) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: f['isin'] as TextEditingController,
                    maxLength: 12,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    ],
                    style: const TextStyle(
                        color: _kTexto, fontSize: 14, letterSpacing: 0.5),
                    cursorColor: _kAzul,
                    onChanged: (_) =>
                        setState(() => f['isin_sugerido'] = false),
                    decoration: deco('ISIN del valor',
                        error: isinMal
                            ? 'ISIN no válido (revisa letras y dígito de control)'
                            : null),
                  ),
                  if (f['isin_sugerido'] == true && !isinMal)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                          'Propuesto a partir de tus otros brókeres: confírmalo.',
                          style: TextStyle(fontSize: 11.5, color: _kOro)),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: f['cantidad'] as TextEditingController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [_FormatoMilesEs(decimales: 4)],
                          style: const TextStyle(color: _kTexto, fontSize: 14),
                          cursorColor: _kAzul,
                          onChanged: (_) => setState(() {}),
                          decoration: deco('Acciones vendidas'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: f['coste'] as TextEditingController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [_FormatoMilesEs()],
                          style: const TextStyle(color: _kTexto, fontSize: 14),
                          cursorColor: _kAzul,
                          onChanged: (_) => setState(() {}),
                          decoration: deco('Coste de compra', sufijo: '€'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final hasta =
                          DateTime.tryParse((v['fecha'] ?? '').toString()) ??
                              DateTime.now();
                      final elegida = await showDatePicker(
                        context: ctx,
                        initialDate: (f['fecha'] as DateTime?) ?? hasta,
                        firstDate: DateTime(1980),
                        lastDate: hasta,
                        helpText: 'Fecha de compra',
                      );
                      if (elegida != null) setState(() => f['fecha'] = elegida);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorde),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 15, color: _kTextoSec),
                          const SizedBox(width: 8),
                          Text(
                            f['fecha'] == null
                                ? 'Fecha de compra'
                                : fechaEs(isoDe(f['fecha'] as DateTime)),
                            style: TextStyle(
                                fontSize: 13.5,
                                color:
                                    f['fecha'] == null ? _kTextoSec : _kTexto),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Coste de compra: lo que pagaste por esas acciones, con '
                      'las comisiones de la compra. Si las compraste en varias '
                      'veces, pon la fecha de la primera y el coste total.',
                      style: TextStyle(
                          fontSize: 11.5, color: _kTextoSec, height: 1.35)),
                  if (res != null) ...[
                    const SizedBox(height: 8),
                    _filaDato('Resultado de esta venta',
                        (res >= 0 ? '+' : '−') + _eur(res.abs()),
                        destacado: true),
                    if (res < 0)
                      InkWell(
                        onTap: () => setState(
                            () => f['recompra'] = !(f['recompra'] == true)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: f['recompra'] == true,
                              activeColor: _kAzul,
                              visualDensity: VisualDensity.compact,
                              onChanged: (x) =>
                                  setState(() => f['recompra'] = x == true),
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                    'Volví a comprar este valor en los dos '
                                    'meses anteriores o posteriores y lo '
                                    'tenía a 31 de diciembre en un banco o '
                                    'bróker que no he subido.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _kTexto,
                                        height: 1.35)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      }

      return _ventanaApp(
        titulo: 'Ventas que constan en Hacienda',
        icono: Icons.account_balance_outlined,
        ancho: 560,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('Completa estas ventas'),
            const SizedBox(height: 6),
            _parrafo(
                'Tu banco comunicó a Hacienda estas ventas de acciones, pero '
                'no cuánto te costaron. Indica el ISIN, el número de acciones '
                'y la fecha y el coste de compra: con eso calculamos la '
                'ganancia o pérdida y la cruzamos con tus otros brókeres.'),
            const SizedBox(height: 14),
            ...filas.map(tarjetaVenta),
          ],
        ),
        pie: pendientes == 0
            ? null
            : Text(
                pendientes == 1
                    ? 'Falta completar 1 venta'
                    : 'Faltan completar $pendientes ventas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _kRojo,
                    fontWeight: FontWeight.w600)),
        botones: [
          _botonSecundario('Ahora no', () => Navigator.pop(ctx)),
          _botonPrimario(
            'Calcular',
            pendientes == 0
                ? () {
                    confirmado = true;
                    Navigator.pop(ctx);
                  }
                : null,
          ),
        ],
      );
    }),
  );

  if (!confirmado || !context.mounted) return 'false|0';

  // ---------- Guardar lo escrito (para no volver a pedirlo) ----------
  for (final f in filas) {
    guardados[f['codigo'] as String] = {
      'incluida': f['incluida'] == true,
      'isin': (f['isin'] as TextEditingController).text.trim().toUpperCase(),
      'cantidad': _leerNumeroEs((f['cantidad'] as TextEditingController).text),
      'coste_compra': _leerNumeroEs((f['coste'] as TextEditingController).text),
      'fecha_compra': f['fecha'] == null ? null : isoDe(f['fecha'] as DateTime),
      'recompra_externa': f['recompra'] == true,
    };
  }
  await prefs.setString(
      'answer_ventas_hacienda_datos_json', jsonEncode(guardados));

  // ---------- Calcular por entidad y guardar con el resto de brókeres ----------
  final Map<String, List<Map<String, dynamic>>> porEntidad = {};
  final Map<String, String> nombreEntidad = {};
  for (final f in filas) {
    if (f['incluida'] == true) continue;
    final v = f['venta'] as Map;
    final nif = (v['nif_broker'] ?? v['broker'] ?? 'entidad').toString();
    nombreEntidad[nif] = (v['broker'] ?? 'Entidad española').toString();
    final g = guardados[f['codigo']] as Map;
    porEntidad.putIfAbsent(nif, () => []).add({
      'codigo': f['codigo'],
      'isin': g['isin'],
      'nombre': v['emisor'],
      'fecha_venta': v['fecha'],
      'importe_venta': aNum(v['importe_venta']),
      'gastos': aNum(v['gastos']),
      'cantidad': g['cantidad'],
      'fecha_compra': g['fecha_compra'],
      'coste_compra': g['coste_compra'],
      'recompra_externa': g['recompra_externa'],
    });
  }

  var calculadas = 0;
  for (final entry in porEntidad.entries) {
    if (!context.mounted) break;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => _ventanaCargando('Calculando las ventas de '
          '${nombreEntidad[entry.key]}...'),
    );
    String? error;
    Map<String, dynamic> data = {};
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final resp = await http.post(
        Uri.parse('$base/calcular/ventas-hacienda'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'broker': nombreEntidad[entry.key],
          'nif_broker': entry.key,
          'anio_ejercicio': anioEjercicio,
          'ventas': entry.value,
        }),
      );
      final cuerpo = utf8.decode(resp.bodyBytes);
      if (resp.statusCode == 200) {
        data = jsonDecode(cuerpo) as Map<String, dynamic>;
      } else {
        error = 'Error ${resp.statusCode}';
        try {
          error = (jsonDecode(cuerpo) as Map)['detail']?.toString() ?? error;
        } catch (_) {}
      }
    } catch (e) {
      error = '$e';
    }
    if (context.mounted) Navigator.pop(context);

    if (error != null) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (c) => _ventanaApp(
            titulo: 'Ventas que constan en Hacienda',
            icono: Icons.error_outline,
            ancho: 440,
            onCerrar: () => Navigator.pop(c),
            cuerpo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _tituloVentana('No se han podido calcular'),
                const SizedBox(height: 8),
                _parrafo('${nombreEntidad[entry.key]}: $error'),
              ],
            ),
            botones: [_botonPrimario('Cerrar', () => Navigator.pop(c))],
          ),
        );
      }
      continue;
    }

    if (!context.mounted) break;
    final guardado = await guardarResultadoBroker(
      context,
      data['id_broker']?.toString() ?? 'hacienda:${entry.key}',
      '${nombreEntidad[entry.key]} (datos de Hacienda)',
      jsonEncode(data),
    );
    if (guardado.startsWith('true')) calculadas += entry.value.length;
  }

  return calculadas > 0 ? 'true|$calculadas' : 'false|0';
}

/// ISIN: 2 letras, 9 alfanuméricos y dígito de control (Luhn).
bool _isinValido(String s) {
  s = s.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$').hasMatch(s)) return false;
  final b = StringBuffer();
  for (final c in s.split('')) {
    final u = c.codeUnitAt(0);
    b.write(u >= 65 ? (u - 55).toString() : c);
  }
  final d = b.toString();
  var total = 0;
  for (var i = 0; i < d.length; i++) {
    var n = int.parse(d[d.length - 1 - i]);
    if (i % 2 == 1) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    total += n;
  }
  return total % 10 == 0;
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
