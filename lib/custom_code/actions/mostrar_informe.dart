// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

Future mostrarInforme(BuildContext context, String resultadoJson) async {
  const Color azul = Color(0xFF1B3A6B);
  const Color verde = Color(0xFF0F6E56);
  const Color verdeFondo = Color(0xFFE1F5EE);
  const Color crema = Color(0xFFFAFAF8);
  const Color textoSec = Color(0xFF6B7280);
  const Color borde = Color(0xFFE5E7EB);

  Map<String, dynamic> r;
  try {
    r = jsonDecode(resultadoJson);
  } catch (e) {
    r = {'error': true, 'mensaje': 'No se pudo leer el resultado'};
  }

  String euro(dynamic v) {
    final n = (v ?? 0).toDouble();
    final abs = n.abs();
    final partes = abs.toStringAsFixed(2).split('.');
    final entero = partes[0];
    final decimales = partes[1];
    final buffer = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
      buffer.write(entero[i]);
    }
    return '${buffer.toString()},$decimales €';
  }

  if (r['error'] == true) {
    await showDialog(
      context: context,
      builder: (c) => _ventanaApp(
        titulo: 'Resultado',
        icono: Icons.error_outline,
        ancho: 440,
        onCerrar: () => Navigator.of(c).pop(),
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('No se ha podido calcular'),
            const SizedBox(height: 8),
            _parrafo(r['mensaje']?.toString() ?? 'Error desconocido'),
          ],
        ),
        botones: [_botonPrimario('Cerrar', () => Navigator.of(c).pop())],
      ),
    );
    return;
  }

  final resultado = (r['resultado'] ?? 0).toDouble();
  final aDevolver = r['a_pagar'] != true;

  Widget fila(String etiqueta, dynamic valor,
      {bool destacado = false, Color? colorValor, bool negativo = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borde, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(etiqueta,
                style: TextStyle(
                    fontSize: 14,
                    color: destacado ? azul : textoSec,
                    fontWeight: destacado ? FontWeight.w600 : FontWeight.w400)),
          ),
          Text('${negativo ? '−' : ''}${euro(valor)}',
              style: TextStyle(
                  fontSize: destacado ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: colorValor ?? azul)),
        ],
      ),
    );
  }

  Widget seccion(String titulo, List<Widget> filas) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borde, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 6),
            child: Text(titulo.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: textoSec,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600)),
          ),
          ...filas,
          SizedBox(height: 6),
        ],
      ),
    );
  }

  await showDialog(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: 720),
        decoration: BoxDecoration(
          color: crema,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: azul,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Resultado de tu declaración',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFFB5D4F4))),
                    SizedBox(height: 6),
                    Text(euro(resultado),
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: aDevolver ? verdeFondo : Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(aDevolver ? 'A devolver' : 'A pagar',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: aDevolver ? verde : Color(0xFF854F0B))),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              seccion('Ingresos y base', [
                fila('Rendimiento neto del trabajo',
                    r['rendimiento_neto_trabajo']),
                fila('Reducción por pensiones', r['reduccion_pensiones'],
                    negativo: true),
                fila('Base liquidable general', r['base_liquidable_general']),
                fila('Base del ahorro', r['base_ahorro']),
              ]),
              seccion('Cuota', [
                fila('Cuota estatal', r['cuota_integra_estatal']),
                fila('Cuota autonómica', r['cuota_integra_autonomica']),
                fila('Cuota íntegra', r['cuota_integra'], destacado: true),
              ]),
              seccion('Pagos a cuenta', [
                fila('Retenciones y pagos a cuenta', r['retenciones'],
                    negativo: true, colorValor: verde),
              ]),
              // Comparación individual vs conjunta (si viene)
              if (r['comparacion'] != null &&
                  r['comparacion']['solo_individual'] != true)
                Builder(builder: (ctx) {
                  final comp = r['comparacion'];
                  final indiv = (comp['individual']?['total'] ?? 0).toDouble();
                  final conj = (comp['conjunta']?['total'] ?? 0).toDouble();
                  final recomendacion = comp['recomendacion']?.toString() ?? '';
                  final ahorro = (comp['ahorro'] ?? 0).toDouble();
                  final conjMejor = recomendacion == 'conjunta';
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: borde, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 8),
                          child: Text('INDIVIDUAL vs CONJUNTA',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: textoSec,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Declaración individual',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: !conjMejor ? azul : textoSec,
                                    fontWeight: !conjMejor
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                            Text(euro(indiv),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !conjMejor ? azul : textoSec)),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Declaración conjunta',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: conjMejor ? azul : textoSec,
                                    fontWeight: conjMejor
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                            Text(euro(conj),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: conjMejor ? azul : textoSec)),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: verdeFondo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            conjMejor
                                ? 'Te conviene la declaración CONJUNTA. Ahorras aproximadamente ${euro(ahorro)}.'
                                : 'Te conviene la declaración INDIVIDUAL. La conjunta te costaría ${euro(ahorro)} más.',
                            style: TextStyle(
                                fontSize: 13,
                                color: verde,
                                fontWeight: FontWeight.w600,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Estimación orientativa. No es una declaración oficial ni se presenta ante la Agencia Tributaria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: textoSec, height: 1.5),
                ),
              ),
              SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(c).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: azul),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Cerrar',
                              style: TextStyle(
                                  color: azul,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(c).pop();
                            await startInterview();
                            await showInterviewDialog(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: azul),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Editar',
                              style: TextStyle(
                                  color: azul,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        final controller =
                            TextEditingController(text: 'Declaración 2025');
                        final nombre = await showDialog<String>(
                          context: context,
                          builder: (dc) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.all(24),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: 380),
                              padding: EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: crema,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nombre de la declaración',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: azul)),
                                  SizedBox(height: 6),
                                  Text(
                                      'Ponle un nombre para reconocerla luego.',
                                      style: TextStyle(
                                          fontSize: 13, color: textoSec)),
                                  SizedBox(height: 16),
                                  TextField(
                                    controller: controller,
                                    autofocus: true,
                                    style: TextStyle(fontSize: 15, color: azul),
                                    decoration: InputDecoration(
                                      hintText: 'Ej: Mi declaración 2025',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: borde),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: azul, width: 2),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.of(dc).pop(),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 13),
                                            side: BorderSide(color: azul),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                          child: Text('Cancelar',
                                              style: TextStyle(
                                                  color: azul,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: TextButton(
                                          onPressed: () => Navigator.of(dc)
                                              .pop(controller.text),
                                          style: TextButton.styleFrom(
                                            backgroundColor: azul,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 13),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                          child: Text('Guardar',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (nombre == null || nombre.trim().isEmpty) return;

                        final res = (r['resultado'] ?? 0).toDouble();
                        final aDev = r['a_pagar'] != true;
                        final guardado =
                            await guardarDeclaracion(res, aDev, nombre.trim());
                        bool ok = false;
                        try {
                          ok = jsonDecode(guardado)['ok'] == true;
                        } catch (e) {}

                        if (ok) {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (sc) {
                              Future.delayed(Duration(milliseconds: 1400), () {
                                Navigator.of(sc).pop();
                              });
                              return Dialog(
                                // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
                                insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 24),
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    color: crema,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: verdeFondo,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.check_circle,
                                            color: verde, size: 44),
                                      ),
                                      SizedBox(height: 16),
                                      Text('Declaración guardada',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: azul)),
                                      SizedBox(height: 4),
                                      Text('"${nombre.trim()}"',
                                          style: TextStyle(
                                              fontSize: 13, color: textoSec)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          Navigator.of(c).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo guardar'),
                              backgroundColor: Colors.redAccent,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: azul,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Guardar declaración',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
