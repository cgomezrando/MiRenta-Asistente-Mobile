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
// Custom Action: mostrarResumenBolsa
// Resumen en lenguaje llano de toda la operativa de bolsa una vez
// analizados TODOS los documentos: número de operaciones, resultado por
// valor, comisiones y otros gastos, dividendos e intereses, pérdidas
// bloqueadas por la regla de los dos meses (también entre brókeres) y
// avisos. Lee lo que guardarResultadoBroker deja en
// answer_cartera_fiscal_json y answer_m06_consolidado_json.
//
// PARÁMETROS: context (BuildContext)
// Include BuildContext: ON. Return Value: OFF.
// Paquetes necesarios: ninguno nuevo.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> mostrarResumenBolsa(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> cartera = {};
  Map<String, dynamic> cons = {};
  try {
    cartera = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_cartera_fiscal_json') ?? '{}'));
  } catch (_) {}
  try {
    cons = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_m06_consolidado_json') ?? '{}'));
  } catch (_) {}
  if (cartera.isEmpty || !context.mounted) return;

  double aNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  // ---------- Agregar la operativa de todos los brókeres ----------
  final nombresBrokers = <String>[];
  var nOrdenes = 0, nLargos = 0, nCortos = 0;
  var comisiones = 0.0,
      cambioDivisa = 0.0,
      margen = 0.0,
      otros = 0.0,
      itf = 0.0;
  var dividendos = 0.0,
      intereses = 0.0,
      retEsp = 0.0,
      retExt = 0.0,
      retExtDed = 0.0;
  var divGan = 0.0, divPer = 0.0, divDif = 0.0;
  final Map<String, double> divisaCant = {};
  final Map<String, double> divisaCoste = {};
  final Map<String, double> prestamoMargen = {};
  final avisos = <String>[];
  // Por valor, fusionando brókeres por ISIN (o símbolo si no hay ISIN).
  final Map<String, Map<String, dynamic>> porValor = {};

  for (final e in cartera.values) {
    if (e is! Map) continue;
    if (e['id'] == 'manual') continue;
    final nombreBroker = e['nombre']?.toString() ?? '';
    final op = (e['operativa'] is Map) ? e['operativa'] as Map : null;
    final rend = (e['rendimientos'] is Map) ? e['rendimientos'] as Map : null;
    if (op != null || rend != null) nombresBrokers.add(nombreBroker);
    if (op != null) {
      nOrdenes += aNum(op['n_ordenes']).round();
      nLargos += aNum(op['n_cierres_largos']).round();
      nCortos += aNum(op['n_cierres_cortos']).round();
      comisiones += aNum(op['comisiones_eur']);
      cambioDivisa += aNum(op['comisiones_cambio_divisa_eur']);
      margen += aNum(op['intereses_margen_eur']);
      otros += aNum(op['otros_gastos_eur']);
      itf += aNum(op['itf_eur']);
      divGan += aNum(op['divisas_ganancias_eur']);
      divPer += aNum(op['divisas_perdidas_eur']);
      divDif += aNum(op['divisas_perdidas_diferidas_eur']);
      final pos = (op['divisas_posicion'] as Map?) ?? {};
      pos.forEach((m, v) {
        divisaCant[m.toString()] =
            (divisaCant[m.toString()] ?? 0) + aNum((v as Map)['cantidad']);
        divisaCoste[m.toString()] =
            (divisaCoste[m.toString()] ?? 0) + aNum(v['coste_eur']);
      });
      final mar = (op['prestamo_margen'] as Map?) ?? {};
      mar.forEach((m, v) {
        prestamoMargen[m.toString()] =
            (prestamoMargen[m.toString()] ?? 0) + aNum(v).abs();
      });
      for (final v in ((op['por_valor'] as List?) ?? [])) {
        final isin = (v['isin']?.toString() ?? '').isNotEmpty
            ? v['isin'].toString()
            : v['simbolo'].toString();
        final fila = porValor.putIfAbsent(
            isin,
            () => {
                  'nombre': v['nombre']?.toString() ?? isin,
                  'resultado': 0.0,
                  'diferido': 0.0,
                  'cierres': 0,
                  'brokers': <String>{},
                });
        // El nombre más corto suele ser el más legible (p. ej. "NVIDIA Corp"
        // frente a "NVIDIA CORP" no importa; frente al ISIN sí).
        final n = v['nombre']?.toString() ?? '';
        if (n.isNotEmpty &&
            (fila['nombre'] == isin ||
                n.length < (fila['nombre'] as String).length)) {
          fila['nombre'] = n;
        }
        fila['resultado'] = aNum(fila['resultado']) + aNum(v['resultado_eur']);
        fila['diferido'] = aNum(fila['diferido']) + aNum(v['diferido_eur']);
        fila['cierres'] = (fila['cierres'] as int) +
            aNum(v['cierres_largos']).round() +
            aNum(v['cierres_cortos']).round();
        (fila['brokers'] as Set<String>).add(nombreBroker);
      }
    }
    if (rend != null) {
      dividendos += aNum(rend['dividendos_eur']);
      intereses += aNum(rend['intereses_eur']);
      retEsp += aNum(rend['retencion_espana_eur']);
      retExt += aNum(rend['retencion_extranjero_eur']);
      retExtDed += aNum(rend['retencion_extranjero_deducible_eur']);
      for (final a in ((rend['avisos'] as List?) ?? [])) {
        avisos.add('$nombreBroker: $a');
      }
    }
  }

  // Pérdidas diferidas por recompra en OTRO bróker: las calcula el backend
  // al consolidar; no están en la operativa de cada bróker.
  final entre = (cons['diferidas_entre_brokers'] as List?) ?? [];
  var diferidoEntre = 0.0;
  for (final d in entre) {
    final isin = d['isin']?.toString() ?? '';
    diferidoEntre += aNum(d['diferido_eur']);
    if (porValor.containsKey(isin)) {
      porValor[isin]!['diferido'] =
          aNum(porValor[isin]!['diferido']) + aNum(d['diferido_eur']);
      porValor[isin]!['entre_brokers'] = true;
    }
  }
  for (final a in ((cons['avisos'] as List?) ?? [])) {
    avisos.add(a.toString());
  }

  final ganancias = aNum(cons['ganancias']);
  final perdidas = aNum(cons['perdidas_deducibles']);
  final diferidas = aNum(cons['perdidas_diferidas']);
  final gananciasC = aNum(cons['ganancias_cortas']);
  final perdidasC = aNum(cons['perdidas_cortas']);

  final valores = porValor.values.toList()
    ..sort((a, b) => aNum(b['resultado']).compareTo(aNum(a['resultado'])));
  final bloqueados = valores.where((v) => aNum(v['diferido']) > 0.005).toList();
  final brokersTexto = nombresBrokers.toSet().toList();
  String listaBrokers() {
    if (brokersTexto.isEmpty) return 'tus brókeres';
    if (brokersTexto.length == 1) return brokersTexto.first;
    return '${brokersTexto.sublist(0, brokersTexto.length - 1).join(', ')} y ${brokersTexto.last}';
  }

  Widget seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(titulo,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: _kAzul)),
      );

  Widget filaValor(Map<String, dynamic> v) {
    final r = aNum(v['resultado']);
    final d = aNum(v['diferido']);
    final color = r >= 0 ? _kVerde : _kRojo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v['nombre'].toString(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, color: _kTexto)),
              ),
              Text('${_numEs((v['cierres'] as int).toDouble(), dec: 0)} op.',
                  style: const TextStyle(fontSize: 11.5, color: _kTextoSec)),
              const SizedBox(width: 10),
              Text((r >= 0 ? '+' : '−') + _eur(r.abs()),
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          if (d > 0.005)
            Text(
              '${_eur(d)} de pérdida bloqueada por la regla de los dos meses'
              '${v['entre_brokers'] == true ? ' (recompra en otro bróker)' : ''}',
              style: const TextStyle(fontSize: 11.5, color: _kOro),
            ),
        ],
      ),
    );
  }

  await showDialog(
    context: context,
    builder: (ctx) => _ventanaApp(
      titulo: 'Resumen de tu bolsa',
      icono: Icons.show_chart,
      ancho: 560,
      onCerrar: () => Navigator.pop(ctx),
      cuerpo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloVentana('Esto es lo que dicen tus extractos'),
          const SizedBox(height: 8),
          _parrafo(
            'Has hecho ${_numEs(nOrdenes.toDouble(), dec: 0)} operaciones en ${listaBrokers()}: '
            '${_numEs(nLargos.toDouble(), dec: 0)} cierres de posiciones largas'
            '${nCortos > 0 ? ' y ${_numEs(nCortos.toDouble(), dec: 0)} de posiciones cortas' : ''}. '
            'Ganancias de ${_eur(ganancias)} y pérdidas deducibles de '
            '${_eur(perdidas)}'
            '${diferidas > 0.005 ? ', con ${_eur(diferidas)} de pérdidas bloqueadas por la regla de los dos meses' : ''}'
            '${(gananciasC > 0.005 || perdidasC > 0.005) ? '. En cortos: ${_eur(gananciasC)} de ganancias y ${_eur(perdidasC)} de pérdidas' : ''}.',
            tam: 14,
            color: _kTexto,
          ),
          seccion('RESULTADO POR VALOR'),
          _tarjeta(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: valores.map(filaValor).toList(),
          )),
          seccion('LO QUE HAS PAGADO'),
          _tarjeta(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filaDato('Comisiones de compra y venta', _eur(comisiones)),
              if (cambioDivisa > 0.005)
                _filaDato('Cambio de divisa', _eur(cambioDivisa)),
              if (margen > 0.005)
                _filaDato('Intereses de la cuenta de margen', _eur(margen)),
              if (itf > 0.005)
                _filaDato(
                    'Impuesto sobre transacciones financieras', _eur(itf)),
              if (otros > 0.005)
                _filaDato('Otras comisiones (conectividad, etc.)', _eur(otros)),
              const SizedBox(height: 6),
              _parrafo(
                  'Las comisiones de compra y venta ya están descontadas del '
                  'resultado de cada operación. Los intereses de margen, el '
                  'cambio de divisa y las comisiones fijas no son deducibles '
                  'en el IRPF.',
                  tam: 12),
            ],
          )),
          if (dividendos > 0.005 || intereses > 0.005) ...[
            seccion('DIVIDENDOS E INTERESES'),
            _tarjeta(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dividendos > 0.005)
                  _filaDato('Dividendos cobrados (íntegros)', _eur(dividendos)),
                if (intereses > 0.005)
                  _filaDato('Intereses cobrados', _eur(intereses)),
                if (retEsp > 0.005)
                  _filaDato('Retención española (a cuenta)', _eur(retEsp)),
                if (retExt > 0.005) ...[
                  _filaDato('Retenido en el extranjero', _eur(retExt)),
                  _filaDato('  deducible por convenio', _eur(retExtDed)),
                ],
              ],
            )),
          ],
          if (divisaCant.isNotEmpty || divGan > 0.005 || divPer > 0.005) ...[
            seccion('DIVISAS'),
            _tarjeta(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filaDato(
                    'Resultado de cambiar divisas a euros',
                    (divGan - divPer >= 0 ? '+' : '−') +
                        _eur((divGan - divPer).abs())),
                if (divDif > 0.005)
                  _filaDato(
                      '  pérdida no deducible este año (recompra en '
                      'menos de un año)',
                      _eur(divDif)),
                const SizedBox(height: 6),
                ...divisaCant.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _parrafo(
                          'Tienes ${_numEs(e.value)} ${e.key} propios en la '
                          'cuenta (efectivo más acciones al coste), que te '
                          'costaron ${_eur(divisaCoste[e.key] ?? 0)}. No '
                          'tributan hasta que los cambies a euros.',
                          tam: 12.5),
                    )),
                const SizedBox(height: 4),
                _parrafo(
                    'Criterio de la DGT (V0282-22 y V0152-26): el resultado '
                    'de cada acción se calcula en su moneda y se pasa a euros '
                    'al cambio del día de la venta; la divisa solo tributa al '
                    'convertirla a euros.',
                    tam: 12),
              ],
            )),
          ],
          if (prestamoMargen.isNotEmpty) ...[
            seccion('PRÉSTAMO DE MARGEN'),
            _avisoCaja(
              'A 31 de diciembre debías ${prestamoMargen.entries.map((e) => '${_numEs(e.value)} ${e.key}').join(' y ')} '
              'al bróker. Con el criterio de la DGT que aplica la app, el '
              'efecto del tipo de cambio sobre ese préstamo ya va dentro del '
              'resultado de las acciones calculado en dólares. Hay otra '
              'interpretación (sentencia del Supremo 71/2021, sobre préstamos '
              'en divisa) que lo haría tributar aparte, en la base general, '
              'al devolverlo. Si tu margen es relevante, conviene '
              'confirmarlo con un asesor.',
              icono: Icons.account_balance_outlined,
            ),
          ],
          if (bloqueados.isNotEmpty) ...[
            seccion('PÉRDIDAS BLOQUEADAS'),
            _avisoCaja(
              'Tienes ${_eur(diferidas)} de pérdidas que este año no puedes '
              'deducir porque recompraste el mismo valor dentro de los dos '
              'meses y seguías teniéndolo a 31 de diciembre'
              '${diferidoEntre > 0.005 ? ' (${_eur(diferidoEntre)} por recompras en otro bróker)' : ''}: '
              '${bloqueados.map((v) => '${v['nombre']} ${_eur(aNum(v['diferido']))}').join(', ')}. '
              'No se pierden: se deducirán cuando vendas esas acciones.',
            ),
          ],
          if (avisos.isNotEmpty) ...[
            seccion('AVISOS'),
            ...avisos.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _avisoCaja(a),
                )),
          ],
          const SizedBox(height: 6),
          _parrafo(
              'Todo esto ya está en el cuestionario: irás confirmando cada '
              'importe al avanzar.',
              tam: 12.5),
        ],
      ),
      botones: [_botonPrimario('Entendido', () => Navigator.pop(ctx))],
    ),
  );
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
