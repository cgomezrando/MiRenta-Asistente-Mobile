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
// Custom Action: gestionarInmuebles
// Muestra un diálogo para añadir/editar/eliminar inmuebles.
// Guarda la lista como JSON en SharedPreferences bajo 'answer_inmuebles_json'.
// Include BuildContext: ON
// ============================================================
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> gestionarInmuebles(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  const azul = Color(0xFF1B3A6B);
  const crema = Color(0xFFFAFAF8);
  const textoSec = Color(0xFF6B7280);
  const oro = Color(0xFFC9A961);

  List<Map<String, dynamic>> inmuebles = [];
  final raw = prefs.getString('answer_inmuebles_json');
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        inmuebles = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> guardar() async {
    await prefs.setString('answer_inmuebles_json', jsonEncode(inmuebles));
  }

  String describir(Map<String, dynamic> inm) {
    final tipo = inm['tipo'] ?? '';
    if (tipo == 'alquilado') {
      final ing = inm['ingresos'] ?? 0;
      return 'Alquilado · ingresos ${_numEs((ing as num).toDouble())} €';
    } else if (tipo == 'disposicion') {
      final vc = inm['valor_catastral'] ?? 0;
      return 'A disposición · valor catastral ${_numEs((vc as num).toDouble())} €';
    }
    return 'Inmueble';
  }

  Future<Map<String, dynamic>?> editarInmueble(
      Map<String, dynamic>? existente) async {
    String tipo = existente?['tipo'] ?? 'disposicion';
    String campoEs(dynamic v) =>
        v is num ? _numEs(v.toDouble()) : (v?.toString() ?? '');
    final ingresosCtrl =
        TextEditingController(text: campoEs(existente?['ingresos']));
    final gastosCtrl =
        TextEditingController(text: campoEs(existente?['gastos']));
    bool esVivienda = existente?['es_vivienda'] ?? true;
    final vcCtrl =
        TextEditingController(text: campoEs(existente?['valor_catastral']));
    bool revisado = existente?['catastral_revisado'] ?? false;
    final diasCtrl =
        TextEditingController(text: existente?['dias']?.toString() ?? '365');
    // Porcentaje de reducción del alquiler de vivienda (0.60, 0.50, 0.70, 0.90)
    double reduccion = (existente?['reduccion_pct'] is num)
        ? (existente!['reduccion_pct'] as num).toDouble()
        : 0.60;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setInner) {
          double parse(TextEditingController c) => _leerNumeroEs(c.text) ?? 0.0;

          Widget campo(String label, TextEditingController ctrl) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrl,
                inputFormatters: [_FormatoMilesEs()],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: textoSec, fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: azul, width: 1.5),
                  ),
                ),
              ),
            );
          }

          return Dialog(
            // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: crema,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos del inmueble',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: azul)),
                    const SizedBox(height: 16),
                    const Text('¿Qué uso tiene?',
                        style: TextStyle(fontSize: 13, color: textoSec)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setInner(() => tipo = 'disposicion'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color:
                                  tipo == 'disposicion' ? azul : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: azul, width: 0.5),
                            ),
                            child: Text('A mi disposición',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: tipo == 'disposicion'
                                        ? Colors.white
                                        : azul)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setInner(() => tipo = 'alquilado'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: tipo == 'alquilado' ? azul : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: azul, width: 0.5),
                            ),
                            child: Text('Alquilado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: tipo == 'alquilado'
                                        ? Colors.white
                                        : azul)),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    if (tipo == 'alquilado') ...[
                      campo('Ingresos anuales del alquiler (€)', ingresosCtrl),
                      campo('Gastos deducibles (€)', gastosCtrl),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'El inquilino la usa como vivienda habitual',
                            style: TextStyle(fontSize: 13)),
                        activeColor: azul,
                        value: esVivienda,
                        onChanged: (v) => setInner(() => esVivienda = v),
                      ),
                      // Selector de reducción solo si es vivienda habitual
                      if (esVivienda) ...[
                        const SizedBox(height: 8),
                        const Text('Reducción aplicable al alquiler',
                            style: TextStyle(fontSize: 13, color: textoSec)),
                        const SizedBox(height: 4),
                        const Text(
                            'Depende de cuándo firmaste el contrato y de la zona.',
                            style: TextStyle(fontSize: 11, color: textoSec)),
                        const SizedBox(height: 8),
                        _opcionReduccion(
                            'Contrato anterior a mayo 2024 (60%)',
                            0.60,
                            reduccion,
                            azul,
                            (v) => setInner(() => reduccion = v)),
                        _opcionReduccion(
                            'Contrato nuevo, caso general (50%)',
                            0.50,
                            reduccion,
                            azul,
                            (v) => setInner(() => reduccion = v)),
                        _opcionReduccion(
                            'Zona tensionada, con rebaja (70%)',
                            0.70,
                            reduccion,
                            azul,
                            (v) => setInner(() => reduccion = v)),
                        _opcionReduccion(
                            'Zona tensionada (90%)',
                            0.90,
                            reduccion,
                            azul,
                            (v) => setInner(() => reduccion = v)),
                        const SizedBox(height: 8),
                      ],
                    ] else ...[
                      campo('Valor catastral (€)', vcCtrl),
                      campo('Días a tu disposición en el año', diasCtrl),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                            'Valor catastral revisado (últimos 10 años)',
                            style: TextStyle(fontSize: 13)),
                        activeColor: azul,
                        value: revisado,
                        onChanged: (v) => setInner(() => revisado = v),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar',
                              style: TextStyle(color: textoSec)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final m = <String, dynamic>{'tipo': tipo};
                            if (tipo == 'alquilado') {
                              m['ingresos'] = parse(ingresosCtrl);
                              m['gastos'] = parse(gastosCtrl);
                              m['es_vivienda'] = esVivienda;
                              if (esVivienda) m['reduccion_pct'] = reduccion;
                            } else {
                              m['valor_catastral'] = parse(vcCtrl);
                              m['catastral_revisado'] = revisado;
                              m['dias'] = parse(diasCtrl).round();
                            }
                            Navigator.pop(ctx, m);
                          },
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Dialog(
          // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: crema,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis inmuebles',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: azul)),
                  const SizedBox(height: 4),
                  const Text(
                      'Añade todos tus inmuebles: los que tienes alquilados y los que están a tu disposición (segundas residencias). No incluyas tu vivienda habitual.',
                      style: TextStyle(fontSize: 12, color: textoSec)),
                  const SizedBox(height: 16),
                  if (inmuebles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Aún no has añadido ningún inmueble.',
                          style: TextStyle(color: textoSec)),
                    )
                  else
                    ...inmuebles.asMap().entries.map((entry) {
                      final i = entry.key;
                      final inm = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: oro, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(describir(inm),
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, size: 18, color: azul),
                              onPressed: () async {
                                final editado = await editarInmueble(inm);
                                if (editado != null) {
                                  setState(() => inmuebles[i] = editado);
                                  await guardar();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () async {
                                setState(() => inmuebles.removeAt(i));
                                await guardar();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azul,
                      side: const BorderSide(color: azul),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir inmueble'),
                    onPressed: () async {
                      final nuevo = await editarInmueble(null);
                      if (nuevo != null) {
                        setState(() => inmuebles.add(nuevo));
                        await guardar();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azul,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size(double.infinity, 46),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

// Widget auxiliar: opción de reducción seleccionable (radio)
Widget _opcionReduccion(String label, double valor, double actual, Color azul,
    void Function(double) onTap) {
  final sel = (actual - valor).abs() < 0.001;
  return InkWell(
    onTap: () => onTap(valor),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20, color: sel ? azul : Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: sel ? azul : Colors.black87,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ),
    ),
  );
}

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
