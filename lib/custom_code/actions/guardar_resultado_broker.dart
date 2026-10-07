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
// Custom Action: guardarResultadoBroker
// Único sitio donde se escriben las respuestas del módulo 6.
//
// Ya no suma cifras: guarda la "huella fiscal" de cada bróker (sus compras
// y ventas) en answer_cartera_fiscal_json, y pide al backend que aplique la
// regla de los 2 meses sobre TODOS los brókeres juntos, porque la ley la
// aplica a la persona y no a la cuenta: si vendes con pérdida en un bróker
// y recompras en otro, la pérdida se difiere igual.
//
// - Volver a subir la misma cuenta la sustituye (no se duplica nada).
// - Subir otro bróker se añade al conjunto.
// - Si el bróker no trae número de cuenta (DEGIRO, plantilla), se pregunta
//   si es el mismo informe u otra cuenta.
// - Si había importes escritos a mano, se pregunta si mantenerlos.
// - Los dividendos, intereses y retenciones que trae el extracto se
//   vuelcan en M05 (ingresos y retenciones españolas), M15 (impuesto pagado
//   en el extranjero, ya limitado al convenio) y marcan 'bróker extranjero'
//   en M06, para que el cuestionario no vuelva a preguntarlos.
// - Si el mismo valor aparece con dos ISIN distintos (p. ej. ArcelorMittal
//   LU1598757687 en Ámsterdam y US03938L2034 en Nueva York), el backend lo
//   sugiere y se pregunta al usuario UNA vez; la decisión se guarda en
//   answer_equivalencias_json y la regla de los 2 meses la aplica entre ISIN.
//
// PARÁMETROS:
//   context (BuildContext)
//   idBroker (String)       -> 'ibkr:U1234567', 'degiro', 'plantilla'...
//   nombreBroker (String)   -> nombre para enseñar al usuario
//   resultadoJson (String)  -> lo que devuelve calcularGanancias...; si trae
//       'huella' participa en la regla entre brókeres; si solo trae
//       'totales' se suma tal cual.
//
// DEVUELVE: 'true|ganancias|perdidas|gananciasCortas|perdidasCortas' con
// los totales CONSOLIDADOS ya guardados, o 'false|0|0|0|0'.
//
// Include BuildContext: ON
// Return Value: ON -> String
// Paquetes necesarios: ninguno nuevo (http y shared_preferences ya están)
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> guardarResultadoBroker(
  BuildContext context,
  String idBroker,
  String nombreBroker,
  String resultadoJson,
) async {
  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  String esp(double v) => _numEs(v);
  double aNum(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> resultado;
  try {
    resultado = jsonDecode(resultadoJson) as Map<String, dynamic>;
  } catch (_) {
    return 'false|0|0|0|0';
  }

  // ---------- 1. Entrada de este bróker ----------
  Map<String, dynamic> entrada;
  if (resultado['huella'] is Map) {
    entrada = {
      'id': idBroker,
      'nombre': nombreBroker,
      'huella': resultado['huella'],
    };
  } else {
    final t = (resultado['totales'] as Map?) ?? {};
    entrada = {
      'id': idBroker,
      'nombre': nombreBroker,
      'totales': {
        'ganancias': aNum(t['ganancias'] ?? resultado['ganancias_largas']),
        'perdidas': aNum(t['perdidas'] ?? resultado['perdidas_largas']),
        'ganancias_cortas':
            aNum(t['ganancias_cortas'] ?? resultado['ganancias_cortas']),
        'perdidas_cortas':
            aNum(t['perdidas_cortas'] ?? resultado['perdidas_cortas']),
      },
    };
  }

  if (resultado['rendimientos'] is Map) {
    entrada['rendimientos'] = resultado['rendimientos'];
  }
  if (resultado['operativa'] is Map) {
    entrada['operativa'] = resultado['operativa'];
  }

  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> cartera = {};
  try {
    cartera = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_cartera_fiscal_json') ?? '{}'));
  } catch (_) {}

  // ---------- 2. ¿Mismo informe u otra cuenta? ----------
  // Una cuenta con número (IBKR) se reconoce sola: si es la misma, se
  // sustituye. Sin número, solo el usuario sabe si es la misma cuenta.
  final conNumero = idBroker.contains(':');
  if (cartera.containsKey(idBroker) && !conNumero && context.mounted) {
    bool esOtra = false;
    bool cancelar = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ventanaApp(
        titulo: nombreBroker,
        icono: Icons.help_outline,
        ancho: 460,
        onCerrar: () => Navigator.pop(ctx), // cancelar: no se guarda nada
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('Ya habías subido $nombreBroker'),
            const SizedBox(height: 8),
            _parrafo('¿Es el mismo informe, que quieres volver a cargar, o '
                'es de otra cuenta distinta en $nombreBroker? Si cierras '
                'esta ventana no se guarda nada.'),
          ],
        ),
        botones: [
          _botonSecundario('Es otra cuenta', () {
            esOtra = true;
            cancelar = false;
            Navigator.pop(ctx);
          }),
          _botonPrimario('Es el mismo', () {
            esOtra = false;
            cancelar = false;
            Navigator.pop(ctx);
          }),
        ],
      ),
    );
    if (cancelar) return 'false|0|0|0|0';
    if (esOtra) {
      var n = 2;
      while (cartera.containsKey('$idBroker#$n')) {
        n++;
      }
      entrada['id'] = '$idBroker#$n';
      entrada['nombre'] = '$nombreBroker (cuenta $n)';
    }
  }

  // ---------- 3. ¿Había importes escritos a mano? ----------
  // Si lo que hay en el cuestionario no coincide con el último cálculo
  // consolidado, el usuario lo escribió o lo corrigió a mano.
  double leer(String clave) =>
      _leerNumeroEs(prefs.getString(clave) ?? '') ?? 0.0;

  // Lo manual es la DIFERENCIA entre lo que hay escrito y el último cálculo
  // consolidado: si el usuario importó 1.000 y luego lo cambió a 1.200, lo
  // manual son 200, no 1.200 (los otros 1.000 ya vienen de los informes).
  final actualG = leer('answer_m06_ganancias');
  final actualP = leer('answer_m06_perdidas');
  Map<String, dynamic> ultimo = {};
  try {
    ultimo = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_m06_consolidado_json') ?? '{}'));
  } catch (_) {}
  final deltaG = actualG - aNum(ultimo['ganancias']);
  final deltaP = actualP - aNum(ultimo['perdidas_deducibles']);
  final hayManual = deltaG.abs() > 0.01 || deltaP.abs() > 0.01;

  if (hayManual && context.mounted) {
    bool mantener = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ventanaApp(
        titulo: nombreBroker,
        icono: Icons.edit_note,
        ancho: 480,
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _tituloVentana('Tienes importes escritos a mano'),
            const SizedBox(height: 8),
            _parrafo('En el cuestionario hay ${esp(deltaG)} € de ganancias y '
                '${esp(deltaP)} € de pérdidas que no vienen de ningún informe '
                'subido.'),
            const SizedBox(height: 8),
            _parrafo('Si son de otro bróker que no vas a subir, mantenlos y '
                'se sumarán. Si eran una estimación de lo que ahora estás '
                'subiendo, descártalos.'),
          ],
        ),
        botones: [
          _botonSecundario('Descartarlos', () {
            mantener = false;
            Navigator.pop(ctx);
          }),
          _botonPrimario('Mantener y sumar', () {
            mantener = true;
            Navigator.pop(ctx);
          }),
        ],
      ),
    );
    if (mantener) {
      final previo = (cartera['manual'] is Map)
          ? Map<String, dynamic>.from(cartera['manual']['totales'] ?? {})
          : <String, dynamic>{};
      cartera['manual'] = {
        'id': 'manual',
        'nombre': 'Importes introducidos a mano',
        'totales': {
          'ganancias': aNum(previo['ganancias']) + deltaG,
          'perdidas': aNum(previo['perdidas']) + deltaP,
          'ganancias_cortas': aNum(previo['ganancias_cortas']),
          'perdidas_cortas': aNum(previo['perdidas_cortas']),
        },
      };
    }
  }

  // ---------- 4. Consolidar todos los brókeres ----------
  final nuevaCartera = Map<String, dynamic>.from(cartera);
  nuevaCartera[entrada['id'] as String] = entrada;

  // Equivalencias de ISIN ya decididas por el usuario en cargas anteriores.
  List<List<String>> aceptadas = [];
  List<List<String>> rechazadas = [];
  try {
    final eq = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_equivalencias_json') ?? '{}'));
    aceptadas = ((eq['aceptadas'] as List?) ?? [])
        .map((g) => (g as List).map((x) => x.toString()).toList())
        .toList();
    rechazadas = ((eq['rechazadas'] as List?) ?? [])
        .map((g) => (g as List).map((x) => x.toString()).toList())
        .toList();
  } catch (_) {}

  Future<Map<String, dynamic>> consolidar() async {
    final resp = await http.post(
      Uri.parse('$base/calcular/consolidar'),
      headers: {
        'Content-Type': 'application/json',
        ...await _cabeceraAuth(),
      },
      body: jsonEncode({
        'brokers': nuevaCartera.values.toList(),
        'equivalencias': aceptadas,
        'equivalencias_rechazadas': rechazadas,
      }),
    );
    final cuerpo = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      String msg = 'Error ${resp.statusCode}';
      try {
        msg = (jsonDecode(cuerpo) as Map)['detail']?.toString() ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
    return jsonDecode(cuerpo) as Map<String, dynamic>;
  }

  Map<String, dynamic> cons;
  try {
    cons = await consolidar();

    // El backend detecta valores con el mismo nombre y distinto ISIN. Solo el
    // usuario sabe si son el mismo valor en dos mercados (misma acción,
    // cuenta para la regla de los 2 meses) o dos valores distintos del mismo
    // emisor. Se pregunta una vez por grupo y se vuelve a consolidar.
    var sugerencias = (cons['sugerencias_equivalencia'] as List?) ?? [];
    var hayCambios = false;
    for (final sug in sugerencias) {
      if (!context.mounted) break;
      final isins =
          ((sug['isins'] as List?) ?? []).map((x) => x.toString()).toList();
      if (isins.length < 2) continue;
      final nombres = (sug['nombres'] as Map?) ?? {};
      bool? mismo;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ventanaApp(
          titulo: 'Regla de los dos meses',
          icono: Icons.compare_arrows,
          ancho: 480,
          cuerpo: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloVentana('¿Es el mismo valor?'),
              const SizedBox(height: 8),
              _parrafo('En tus brókeres aparece el mismo nombre con dos '
                  'códigos ISIN distintos:'),
              const SizedBox(height: 10),
              _tarjeta(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...isins.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('$i — ${nombres[i] ?? ''}',
                            style: const TextStyle(
                                color: _kTexto,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                      )),
                ],
              )),
              const SizedBox(height: 10),
              _parrafo('Si es la misma acción cotizando en dos mercados (por '
                  'ejemplo, la misma empresa en Ámsterdam y en Nueva York), '
                  'Hacienda la trata como un único valor y una recompra en '
                  'uno cuenta para la regla de los dos meses del otro. Si son '
                  'dos valores distintos del mismo emisor, no.'),
            ],
          ),
          botones: [
            _botonSecundario('Son distintos', () {
              mismo = false;
              Navigator.pop(ctx);
            }),
            _botonPrimario('Es el mismo valor', () {
              mismo = true;
              Navigator.pop(ctx);
            }),
          ],
        ),
      );
      if (mismo == null) continue; // sin decisión: se volverá a preguntar
      if (mismo == true) {
        aceptadas.add(isins);
      } else {
        rechazadas.add(isins);
      }
      hayCambios = true;
    }
    if (hayCambios) {
      await prefs.setString('answer_equivalencias_json',
          jsonEncode({'aceptadas': aceptadas, 'rechazadas': rechazadas}));
      cons = await consolidar();
    }
  } catch (e) {
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => _ventanaApp(
          titulo: nombreBroker,
          icono: Icons.error_outline,
          ancho: 440,
          onCerrar: () => Navigator.pop(ctx),
          cuerpo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _tituloVentana('No se ha podido guardar'),
              const SizedBox(height: 8),
              _parrafo('No se ha podido combinar este resultado con tus otros '
                  'brókeres ($e). No se ha cambiado nada; inténtalo de nuevo.'),
            ],
          ),
          botones: [_botonPrimario('Cerrar', () => Navigator.pop(ctx))],
        ),
      );
    }
    return 'false|0|0|0|0';
  }

  // Solo se persiste si la consolidación ha ido bien: nunca se queda la
  // cartera actualizada con unos totales viejos.
  final g = aNum(cons['ganancias']);
  final p = aNum(cons['perdidas_deducibles']);
  final gc = aNum(cons['ganancias_cortas']);
  final pc = aNum(cons['perdidas_cortas']);

  await prefs.setString('answer_cartera_fiscal_json', jsonEncode(nuevaCartera));
  await prefs.setString('answer_m06_ganancias', esp(g));
  await prefs.setString('answer_m06_perdidas', esp(p));
  await prefs.setString('answer_m06_ganancias_cortas', esp(gc));
  await prefs.setString('answer_m06_perdidas_cortas', esp(pc));
  await prefs.setString('answer_m06_tiene_ventas', 'Sí');
  await prefs.setString('answer_m06_consolidado_json', jsonEncode(cons));
  // IBKR, DEGIRO y cualquier plantilla son brókeres no españoles: no hay que
  // volver a preguntarlo.
  await prefs.setString('answer_m06_broker_extranjero', 'Sí');

  // Procedencia de cada importe (la ventana del cuestionario la enseña en
  // verde y la pregunta pasa a ser una confirmación) y puertas de sí/no que
  // ya no hace falta preguntar (answer__auto_<id>: goToNextQuestion las salta).
  String origenBrokers(String campo) {
    final partes = <String>[];
    for (final b in ((cons['por_broker'] as List?) ?? [])) {
      final v = aNum(b[campo]);
      if (v.abs() > 0.005) partes.add('${b['nombre']} ${esp(v)} €');
    }
    return partes.join(' · ');
  }

  Future<void> marcarImportado(String id, String origen) async {
    if (origen.isEmpty) return;
    await prefs.setString('answer__origen_$id', origen);
  }

  Future<void> saltarPuerta(String id) async {
    await prefs.setString('answer__auto_$id', '1');
  }

  await marcarImportado('m06_ganancias', origenBrokers('ganancias'));
  await marcarImportado('m06_perdidas', origenBrokers('perdidas_deducibles'));
  await marcarImportado(
      'm06_ganancias_cortas', origenBrokers('ganancias_cortas'));
  await marcarImportado(
      'm06_perdidas_cortas', origenBrokers('perdidas_cortas'));
  await saltarPuerta('m06_tiene_ventas');
  await saltarPuerta('m06_broker_extranjero');

  // ---------- 4b. Dividendos, intereses y retenciones ----------
  // Se suman los de todos los brókeres de la cartera. Lo que el usuario
  // hubiera escrito a mano (o importado de la AEAT) por encima de lo que
  // aportaron los brókeres la última vez se conserva: solo se sustituye la
  // parte que viene de los extractos.
  double sumaRend(String clave) {
    var t = 0.0;
    for (final e in nuevaCartera.values) {
      if (e is Map && e['rendimientos'] is Map) {
        t += aNum((e['rendimientos'] as Map)[clave]);
      }
    }
    return t;
  }

  final rendNuevo = {
    'm05_dividendos': sumaRend('dividendos_eur'),
    'm05_intereses': sumaRend('intereses_eur'),
    'm05_retenciones_capital': sumaRend('retencion_espana_eur'),
    'm15_importe_retenido': sumaRend('retencion_extranjero_deducible_eur'),
  };
  Map<String, dynamic> rendPrevio = {};
  try {
    rendPrevio = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('answer_m05_brokers_json') ?? '{}'));
  } catch (_) {}
  for (final entry in rendNuevo.entries) {
    final manual = leer('answer_${entry.key}') - aNum(rendPrevio[entry.key]);
    final total = (manual > 0 ? manual : 0.0) + entry.value;
    if (total > 0.005 || entry.value > 0.005) {
      await prefs.setString('answer_${entry.key}', esp(total));
    }
  }
  await prefs.setString('answer_m05_brokers_json', jsonEncode(rendNuevo));

  String origenRend(String clave) {
    final partes = <String>[];
    for (final e in nuevaCartera.values) {
      if (e is Map && e['rendimientos'] is Map) {
        final v = aNum((e['rendimientos'] as Map)[clave]);
        if (v > 0.005) partes.add('${e['nombre']} ${esp(v)} €');
      }
    }
    return partes.join(' · ');
  }

  if (rendNuevo['m05_dividendos']! > 0.005) {
    await prefs.setString('answer_m05_tiene_dividendos', 'Sí');
    await saltarPuerta('m05_tiene_dividendos');
    await marcarImportado('m05_dividendos', origenRend('dividendos_eur'));
  }
  if (rendNuevo['m05_intereses']! > 0.005) {
    await prefs.setString('answer_m05_tiene_intereses', 'Sí');
    await saltarPuerta('m05_tiene_intereses');
    await marcarImportado('m05_intereses', origenRend('intereses_eur'));
  }
  if (rendNuevo['m05_retenciones_capital']! > 0.005) {
    await prefs.setString('answer_m05_tiene_retenciones_capital', 'Sí');
    await saltarPuerta('m05_tiene_retenciones_capital');
    await marcarImportado(
        'm05_retenciones_capital', origenRend('retencion_espana_eur'));
  }
  final retExtranjero = sumaRend('retencion_extranjero_eur');
  // 'pais_principal' solo viene informado cuando hay cobros de pagadores no
  // españoles.
  var hayRentasExtranjero = retExtranjero > 0.005;
  for (final e in nuevaCartera.values) {
    if (e is Map &&
        e['rendimientos'] is Map &&
        ((e['rendimientos'] as Map)['pais_principal'] ?? '')
            .toString()
            .isNotEmpty) {
      hayRentasExtranjero = true;
    }
  }
  if (hayRentasExtranjero) {
    await prefs.setString('answer_m15_rentas_extranjero', 'Sí');
    await saltarPuerta('m15_rentas_extranjero');
  }
  if (retExtranjero > 0.005) {
    await prefs.setString('answer_m15_retencion_origen', 'Sí');
    await saltarPuerta('m15_retencion_origen');
    await marcarImportado(
        'm15_importe_retenido',
        origenRend('retencion_extranjero_deducible_eur') +
            ' (deducible según convenio)');
    // País con más renta: el que decide el convenio que se aplica.
    String pais = '';
    var mayor = 0.0;
    for (final e in nuevaCartera.values) {
      if (e is Map && e['rendimientos'] is Map) {
        final r = e['rendimientos'] as Map;
        final b = aNum(r['dividendos_eur']) + aNum(r['intereses_eur']);
        if (b > mayor &&
            (r['pais_principal_nombre'] ?? '').toString().isNotEmpty) {
          mayor = b;
          pais = r['pais_principal_nombre'].toString();
        }
      }
    }
    if (pais.isNotEmpty) {
      await prefs.setString('answer_m15_pais', pais);
    }
  }
  // Lo que ha cambiado al cruzar brókeres (pérdidas diferidas entre
  // cuentas, avisos) lo enseña mostrarResumenBolsa al terminar el análisis
  // de todos los documentos; queda en answer_m06_consolidado_json.

  return 'true|$g|$p|$gc|$pc';
}

/// Cabecera de autenticación para la API de cálculo: el ID token de
/// Firebase del usuario que ha iniciado sesión (FirebaseAuth lo renueva solo
/// si ha caducado). Sin sesión no se envía y la API responde 401.
Future<Map<String, String>> _cabeceraAuth() async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  return (token == null || token.isEmpty)
      ? <String, String>{}
      : {'Authorization': 'Bearer $token'};
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
