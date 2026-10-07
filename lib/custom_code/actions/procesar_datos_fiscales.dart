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
// Custom Action: procesarDatosFiscales
// Sube el PDF de Datos Fiscales de la AEAT, propone los valores que ha
// leido y, SOLO si el usuario lo confirma, los escribe en las respuestas
// del cuestionario.
//
// Nunca pisa una respuesta en silencio: lo que va a sobrescribir algo que
// el usuario ya habia escrito se marca en rojo con el valor anterior a la
// vista, y cada linea se puede desmarcar.
//
// PARAMETROS:
//   context (BuildContext)
//   archivoPdf (FFUploadedFile) -> lo devuelve elegirArchivoPdf()
//   anioEjercicio (int) -> el ejercicio que se esta declarando
//
// DEVUELVE: 'true|<numero de campos aplicados>' o 'false|0'
//
// Include BuildContext: ON
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/uploaded_file.dart';
import '/custom_code/actions/index.dart';

Future<String> procesarDatosFiscales(
  BuildContext context,
  FFUploadedFile archivoPdf,
  int anioEjercicio,
) async {
  // Colores de la estética común (definidos al final del archivo).
  const azul = _kAzul;
  const textoSec = _kTextoSec;
  const textoPrin = _kTexto;
  const rojo = _kRojo;

  final bytes = archivoPdf.bytes;
  if (bytes == null || bytes.isEmpty) return 'false|0';

  String esp(double v) => _numEs(v);

  // ---------- 1. Llamada al backend ----------
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ventanaCargando('Leyendo tus datos fiscales...'),
  );

  final respuesta = await extraerDatosFiscalesAeat(archivoPdf);
  if (context.mounted) Navigator.pop(context);

  Map<String, dynamic> data;
  try {
    data = jsonDecode(respuesta) as Map<String, dynamic>;
  } catch (e) {
    return 'false|0';
  }

  if (data['ok'] != true) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => _ventanaApp(
          titulo: 'Datos fiscales de la AEAT',
          icono: Icons.error_outline,
          ancho: 440,
          onCerrar: () => Navigator.pop(ctx),
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('No se ha podido leer el documento'),
              const SizedBox(height: 8),
              _parrafo(data['mensaje']?.toString() ?? 'Error desconocido.'),
            ],
          ),
          botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
        ),
      );
    }
    return 'false|0';
  }

  // ---------- 2. Interpretar la respuesta ----------
  final casillas = Map<String, dynamic>.from(data['casillas'] ?? {});
  final secciones = (data['secciones'] as List?) ?? [];
  final pendientes =
      Map<String, dynamic>.from(data['perdidas_pendientes'] ?? {});
  final ventas = (data['ventas'] as List?) ?? [];
  final ejercicioPdf = data['ejercicio'];

  double aNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return _leerNumeroEs(v.toString()) ?? 0.0;
  }

  double casilla(String c) => aNum(casillas[c]);

  // Prevision social: la AEAT ofrece varias casillas posibles, asi que la
  // casilla no sirve. Lo que si distingue el documento es la CLAVE de cada
  // registro: "contribuciones del promotor" es lo que aporta la empresa y
  // el resto es aportacion del trabajador.
  double aportTrabajador = 0.0;
  double contribEmpresa = 0.0;
  for (final s in secciones) {
    if (s is! Map) continue;
    final titulo = (s['seccion'] ?? '').toString().toUpperCase();
    if (!titulo.contains('PREVISI')) continue;
    for (final r in ((s['registros'] as List?) ?? [])) {
      if (r is! Map) continue;
      double importe = 0.0;
      r.forEach((k, v) {
        if (k.toString().toUpperCase().startsWith('APORTACI') && v is num) {
          importe = v.toDouble();
        }
      });
      if (importe == 0.0) continue;
      final texto = r.values.join(' ').toLowerCase();
      if (texto.contains('promotor')) {
        contribEmpresa += importe;
      } else {
        aportTrabajador += importe;
      }
    }
  }

  // Las pérdidas pendientes van al cuestionario AÑO POR AÑO: se compensan
  // empezando por las más antiguas y cada una caduca a los cuatro ejercicios,
  // así que el total sin desglosar perdería información.

  // Brokers que constan a Hacienda: sirve para avisar al usuario de que
  // tiene ventas de valores que quiza no haya aportado.
  final brokers = <String>{};
  for (final v in ventas) {
    if (v is Map && v['broker'] != null) {
      brokers.add(v['broker'].toString());
    }
  }

  // ---------- 3. Construir las propuestas ----------
  final propuestas = <Map<String, dynamic>>[];
  void proponer(String id, String etiqueta, double valor) {
    if (valor == 0.0) return;
    propuestas.add({
      'id': id,
      'etiqueta': etiqueta,
      'valor': valor,
      'marcado': true,
      'anterior': '',
    });
  }

  proponer(
      'm02_gross_income', 'Ingresos integros del trabajo', casilla('0003'));
  proponer('m02_especie', 'Retribuciones en especie', casilla('0007'));
  proponer('m02_withholdings', 'Retenciones del trabajo', casilla('0596'));
  proponer('m02_social_security', 'Seguridad Social', casilla('0013'));
  proponer('m05_intereses', 'Intereses de cuentas bancarias', casilla('0027'));
  proponer('m05_retenciones_capital', 'Retenciones de capital mobiliario',
      casilla('0597'));
  proponer('m05_gastos_capital', 'Gastos de administracion y custodia',
      casilla('0037'));
  proponer('m12_aportacion_trabajador', 'Tu aportacion al plan de pensiones',
      aportTrabajador);
  proponer('m12_contribucion_empresa', 'Contribucion de la empresa al plan',
      contribEmpresa);
  // Los cuatro ejercicios anteriores salen del año que se declara: asi no
  // hay que tocar esto cada año.
  for (var d = 4; d >= 1; d--) {
    final anio = '${anioEjercicio - d}';
    proponer('m06_perdidas_pendientes_$anio', 'Perdidas pendientes de $anio',
        aNum(pendientes[anio]));
  }

  final prefs = await SharedPreferences.getInstance();
  for (final p in propuestas) {
    p['anterior'] = prefs.getString('answer_${p['id']}') ?? '';
  }

  if (propuestas.isEmpty) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => _ventanaApp(
          titulo: 'Datos fiscales de la AEAT',
          icono: Icons.info_outline,
          ancho: 440,
          onCerrar: () => Navigator.pop(ctx),
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('Nada que importar'),
              const SizedBox(height: 8),
              _parrafo('El documento se ha leído correctamente, pero no '
                  'contiene importes que encajen con las preguntas del '
                  'cuestionario.'),
            ],
          ),
          botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
        ),
      );
    }
    return 'false|0';
  }

  // ---------- 4. Pantalla de confirmacion ----------
  bool confirmado = false;
  if (!context.mounted) return 'false|0';

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        final seleccionados =
            propuestas.where((p) => p['marcado'] == true).length;
        final pisados = propuestas
            .where((p) =>
                p['marcado'] == true &&
                (p['anterior'] as String).trim().isNotEmpty &&
                ((_leerNumeroEs(p['anterior'] as String) ?? 0.0) -
                            (p['valor'] as double))
                        .abs() >
                    0.005)
            .length;

        return _ventanaApp(
          titulo: 'Datos fiscales de la AEAT',
          icono: Icons.account_balance_outlined,
          ancho: 540,
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('Esto es lo que dice Hacienda'),
              const SizedBox(height: 6),
              _parrafo('Revisa cada importe antes de aplicarlo. Desmarca el '
                  'que no quieras que se copie al cuestionario.'),
              if (ejercicioPdf != null &&
                  ejercicioPdf is int &&
                  ejercicioPdf != anioEjercicio) ...[
                const SizedBox(height: 10),
                _avisoCaja(
                    'Atención: este documento es del ejercicio $ejercicioPdf '
                    'y estás declarando $anioEjercicio.',
                    color: _kRojo,
                    icono: Icons.warning_amber_rounded),
              ],
              const SizedBox(height: 14),
              ...propuestas.map((p) {
                final anterior = (p['anterior'] as String).trim();
                final nuevo = esp(p['valor'] as double);
                final pisa = anterior.isNotEmpty &&
                    ((_leerNumeroEs(anterior) ?? 0.0) - (p['valor'] as double))
                            .abs() >
                        0.005;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () =>
                        setState(() => p['marcado'] = p['marcado'] != true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pisa
                              ? _kRojo.withOpacity(0.45)
                              : (p['marcado'] == true ? _kAzul : _kBorde),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: p['marcado'] == true,
                            activeColor: _kAzul,
                            onChanged: (v) =>
                                setState(() => p['marcado'] = v == true),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['etiqueta'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13.5, color: _kTexto)),
                                if (pisa)
                                  Text(
                                    'Sustituye a ${_numEs(_leerNumeroEs(anterior) ?? 0.0)} € que habías puesto',
                                    style: const TextStyle(
                                        fontSize: 11, color: _kRojo),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$nuevo €',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kAzul)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (brokers.isNotEmpty) ...[
                const SizedBox(height: 4),
                _avisoCaja(
                    'Hacienda tiene constancia de ${ventas.length} venta(s) '
                    'de valores en: ${brokers.join(', ')}. No sabe cuánto te '
                    'costaron: al analizar los documentos te pediremos el '
                    'ISIN, el número de acciones y la fecha y el coste de '
                    'compra de cada una.'),
              ],
            ],
          ),
          pie: pisados == 0
              ? null
              : Text(
                  pisados == 1
                      ? '1 respuesta tuya será sustituida'
                      : '$pisados respuestas tuyas serán sustituidas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: _kRojo, fontWeight: FontWeight.w600),
                ),
          botones: [
            _botonSecundario('Cancelar', () => Navigator.pop(ctx)),
            _botonPrimario(
              seleccionados == 0
                  ? 'Nada seleccionado'
                  : 'Aplicar $seleccionados valor(es)',
              seleccionados == 0
                  ? null
                  : () {
                      confirmado = true;
                      Navigator.pop(ctx);
                    },
            ),
          ],
        );
      });
    },
  );

  if (!confirmado) return 'false|0';

  // ---------- 5. Escribir las respuestas ----------
  int aplicados = 0;
  final aplicadosIds = <String>{};
  for (final p in propuestas) {
    if (p['marcado'] != true) continue;
    await prefs.setString('answer_${p['id']}', esp(p['valor'] as double));
    // Procedencia: el cuestionario enseña el importe como confirmación.
    await prefs.setString(
        'answer__origen_${p['id']}', 'Datos fiscales de la AEAT');
    aplicadosIds.add(p['id'].toString());
    aplicados++;
  }

  // Puertas de sí/no que los datos fiscales ya han contestado: se marcan
  // en answer__auto_<id> y goToNextQuestion las salta.
  Future<void> abrirPuerta(String puerta, bool condicion) async {
    if (!condicion) return;
    await prefs.setString('answer_$puerta', 'Sí');
    await prefs.setString('answer__auto_$puerta', '1');
  }

  await abrirPuerta('m02_especie_si', aplicadosIds.contains('m02_especie'));
  // La cifra de retribuciones dinerarias de Hacienda ya viene con la parte
  // exenta del art. 7p descontada por la empresa. La pregunta de trabajo en
  // el extranjero pasa a ser "¿días ADICIONALES no descontados?" (la
  // reformula showInterviewDialog) y la de "¿tu empresa ya lo descontó?"
  // sobra: si contesta que hubo días adicionales, es que no están
  // descontados.
  if (aplicadosIds.contains('m02_gross_income')) {
    await prefs.setString('answer_m02_7p_ya_aplicada', 'No');
    await prefs.setString('answer__auto_m02_7p_ya_aplicada', '1');
  }
  await abrirPuerta(
      'm05_tiene_intereses', aplicadosIds.contains('m05_intereses'));
  await abrirPuerta('m05_tiene_retenciones_capital',
      aplicadosIds.contains('m05_retenciones_capital'));
  await abrirPuerta(
      'm05_gastos_capital_si', aplicadosIds.contains('m05_gastos_capital'));
  await abrirPuerta(
      'm12_tiene_plan',
      aplicadosIds.contains('m12_aportacion_trabajador') ||
          aplicadosIds.contains('m12_contribucion_empresa'));
  await abrirPuerta('m06_tiene_pendientes',
      aplicadosIds.any((id) => id.startsWith('m06_perdidas_pendientes')));

  // Hacienda sabe que hubo ventas pero no su coste: la puerta se deja en
  // "Sí" pero se sigue enseñando, porque el importe lo aporta el bróker.
  if (ventas.isNotEmpty) {
    await prefs.setString('answer_m06_tiene_ventas', 'Sí');
  }
  // Las ventas que constan en Hacienda las completa después
  // completarVentasHacienda (ISIN, acciones, fecha y coste de compra).
  if (ventas.isNotEmpty) {
    await prefs.setString('answer_ventas_hacienda_json', jsonEncode(ventas));
  } else {
    await prefs.remove('answer_ventas_hacienda_json');
  }

  if (context.mounted) {
    await showDialog(
      context: context,
      builder: (ctx) => _ventanaApp(
        titulo: 'Datos fiscales de la AEAT',
        icono: Icons.check_circle_outline,
        ancho: 440,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('Datos importados'),
            const SizedBox(height: 8),
            _parrafo('Se han rellenado $aplicados campos del cuestionario. '
                'Revísalos según avances: siguen siendo tu responsabilidad.'),
          ],
        ),
        botones: [_botonPrimario('Continuar', () => Navigator.pop(ctx))],
      ),
    );
  }

  return 'true|$aplicados';
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
