// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

Future<String> calcularDeclaracion() async {
  final prefs = await SharedPreferences.getInstance();

  String getA(String id) => prefs.getString('answer_$id') ?? '';

  // Admite "75.891,42", "75891,42" y "75891.42" (antes este último se
  // leía como 7.589.142).
  double num(String id) => _leerNumeroEs(getA(id)) ?? 0.0;

  int intv(String id) => num(id).round();

  // Las pérdidas pendientes se preguntan por ejercicio, porque se compensan
  // empezando por las más antiguas y caducan a los cuatro años. El motor
  // recibe el total, pero guardarlas por año permite avisar de las que están
  // a punto de caducar y cuadra con lo que devuelven los datos fiscales.
  double pendientesAnteriores() {
    final porAnio = num('m06_perdidas_pendientes_2021') +
        num('m06_perdidas_pendientes_2022') +
        num('m06_perdidas_pendientes_2023') +
        num('m06_perdidas_pendientes_2024');
    // Respuesta antigua de una sola cifra, por si el usuario ya la tenía
    // guardada de una versión anterior del cuestionario.
    return porAnio > 0 ? porAnio : num('m06_perdidas_pendientes');
  }

  bool si(String id) => getA(id).trim().toLowerCase() == 'sí';

  String comunidad() {
    final c = getA('m01_comunidad').trim();
    const mapa = {
      'Andalucía': 'andalucia',
      'Aragón': 'aragon',
      'Asturias': 'asturias',
      'Canarias': 'canarias',
      'Cantabria': 'cantabria',
      'Castilla-La Mancha': 'castilla_la_mancha',
      'Castilla y León': 'castilla_leon',
      'Cataluña': 'cataluna',
      'Comunidad Valenciana': 'valencia',
      'Extremadura': 'extremadura',
      'Galicia': 'galicia',
      'Islas Baleares': 'baleares',
      'La Rioja': 'rioja',
      'Madrid': 'madrid',
      'Murcia': 'murcia',
    };
    return mapa[c] ?? 'referencia';
  }

  int gradoDiscapacidad() {
    final g = getA('m04_grado_discapacidad');
    if (g.contains('65')) return 65;
    if (g.contains('33')) return 33;
    return 0;
  }

  int edad = 0;
  final fechaNac = getA('m01_birth_date');
  if (fechaNac.isNotEmpty) {
    try {
      final partes = fechaNac.split('-');
      final anioNac = int.parse(partes[0]);
      final ahora = DateTime.now();
      edad = ahora.year - anioNac;
    } catch (e) {
      edad = 0;
    }
  }

  String famNumerosa() {
    final v = getA('m13_familia_numerosa').toLowerCase();
    if (v.contains('especial')) return 'especial';
    if (v.contains('general')) return 'general';
    return '';
  }

// Leer la lista de inmuebles (guardada por gestionarInmuebles)
  List<dynamic> inmuebles = [];
  final inmueblesRaw = prefs.getString('answer_inmuebles_json');
  if (inmueblesRaw != null && inmueblesRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(inmueblesRaw);
      if (decoded is List) inmuebles = decoded;
    } catch (e) {
      inmuebles = [];
    }
  }
  final datos = {
    'ingreso_integro_trabajo': num('m02_gross_income'),
    'retribucion_especie': num('m02_especie'),
    'seguridad_social': num('m02_social_security'),
    'retenciones': num('m02_withholdings'),
    'edad': edad,
    'tiene_trabajo_extranjero': si('m02_foreign_work'),
    'importe_exento_7p': num('m02_7p_importe'),
    'dias_extranjero': intv('m02_foreign_days'),
    'num_hijos': intv('m03_num_hijos'),
    'hijos_menores_3': intv('m03_hijos_menores_3'),
    'grado_discapacidad': gradoDiscapacidad(),
    'comunidad': comunidad(),
    'dividendos': num('m05_dividendos'),
    'intereses': num('m05_intereses'),
    'retenciones_capital': num('m05_retenciones_capital'),
    'gastos_capital_mobiliario': num('m05_gastos_capital'),
    'perdidas_pendientes_anteriores': pendientesAnteriores(),
    'aportacion_empleo_trabajador': num('m12_aportacion_trabajador'),
    'contribucion_empresa': num('m12_contribucion_empresa'),
    'donativos': num('m11_importe_donativos'),
    'hijos_nacidos_ejercicio': intv('m13_hijos_nacidos'),
    'es_joven_alquiler': si('m13_es_joven_alquiler'),
    'alquiler_pagado_anual': num('m13_alquiler_pagado'),
    'gastos_escolaridad': num('m13_gastos_escolaridad'),
    'gastos_idiomas': num('m13_gastos_idiomas'),
    'gastos_vestuario_escolar': num('m13_gastos_vestuario'),
    'cuotas_empleada_hogar': num('m13_cuotas_hogar'),
    'ascendientes_a_cargo': intv('m04_num_ascendientes'),
    'tipo_familia_numerosa': famNumerosa(),
    'gastos_guarderia': num('m13ar_gastos_guarderia'),
    'gastos_clases_apoyo': num('m13ar_clases_apoyo'),
    'personas_dependientes': intv('m04_num_ascendientes'),
    'inversion_nuevas_entidades': num('m13_inversion_nuevas'),
    'inversion_tipo_especial': si('m13_inversion_especial'),
    'es_familia_monoparental': si('m13_monoparental'),
    'contribuyente_con_discapacidad': si('m04_discapacidad_propia'),
    'es_viudo_reciente': si('m13_es_viudo'),
    'tiene_hijos_a_cargo': si('m03_tiene_hijos'),
    'gastos_rehabilitacion_vivienda': num('m13_gastos_rehabilitacion'),
    'hijos_3_a_5_anos': intv('m13_hijos_3_5'),
    'hijos_material_escolar': intv('m13_material_escolar'),
    'gasto_abonos_culturales': num('m13_abonos_culturales'),
    'adopciones_ejercicio': intv('m13_adopciones'),
    'adopcion_internacional_cyl': si('m13_adopcion_internacional'),
    'inmuebles': inmuebles,
    'retenciones_ganancias': num('m06_retenciones_ganancias'),
    'trabajador_activo': si('m04_trabajador_activo'),
    'movilidad_geografica': si('m04_movilidad_geografica'),
    'anualidades_alimentos_hijos': num('m03_anualidades_alimentos'),
    // Cuota sindical
    'cuota_sindical': num('m02_union_fee'),
    // Ganancias y pérdidas de la base del ahorro: acciones (M06) + fondos
    // (M07) + posiciones cortas (M06). Las ventas en corto se integran como
    // ganancia/pérdida patrimonial al cierre de la posición; no hay consulta
    // vinculante de la DGT que fije otro tratamiento, así que se sigue el
    // criterio general del art. 33 LIRPF.
    'ganancias_patrimoniales': num('m06_ganancias') +
        num('m07_ganancia_fondos') +
        num('m06_ganancias_cortas'),
    'perdidas_patrimoniales': num('m06_perdidas') +
        num('m07_perdida_fondos') +
        num('m06_perdidas_cortas'),
    // Venta de inmuebles (M08)
    'venta_inmueble_transmision': num('m08_valor_venta'),
    'venta_inmueble_adquisicion': num('m08_valor_compra'),
    'reinversion_vivienda': si('m08_reinversion'),
    'importe_reinvertido': num('m08_importe_reinvertido'),
    'mayor_65_vivienda_habitual': (edad >= 65 && si('m08_era_habitual')),
    // Vivienda habitual / hipoteca (M10)
    'vivienda_habitual_anterior_2013': si('m10_hipoteca_anterior_2013'),
    'pago_hipoteca_anual': num('m10_pago_hipoteca'),
    // Doble imposición internacional (M15)
    'deduccion_doble_imposicion_int': num('m15_importe_retenido'),
  };

  const base = 'https://mirenta-api-976371529191.europe-west1.run.app';

  try {
    // 1. Cálculo individual (declaración principal)
    final resp = await http.post(
      Uri.parse('$base/calcular/irpf'),
      headers: {
        'Content-Type': 'application/json',
        ...await _cabeceraAuth(),
      },
      body: jsonEncode(datos),
    );
    if (resp.statusCode != 200) {
      String msg = 'Error ${resp.statusCode}';
      try {
        msg = (jsonDecode(utf8.decode(resp.bodyBytes)) as Map)['detail']
                ?.toString() ??
            msg;
      } catch (_) {}
      return jsonEncode({'error': true, 'mensaje': msg});
    }

    // ¿Casado y quiere comparar con la conjunta?
    final casado = getA('m01_civil_status').trim().toLowerCase() == 'casado/a';
    final quiereComparar = si('m01_conjunta_posible');

    if (!casado || !quiereComparar) {
      // Sin comparación: devolvemos el resultado individual tal cual
      return resp.body;
    }

    // 2. Datos del cónyuge (módulo M14)
    final conyuge = {
      'ingreso_integro_trabajo': num('m14_conyuge_trabajo'),
      'seguridad_social': num('m14_conyuge_ss'),
      'retenciones': num('m14_conyuge_retenciones'),
      'dividendos': num('m14_conyuge_capital'),
      'edad': 0,
    };

    // 3. Datos de la unidad familiar
    final unidad = {
      'comunidad': comunidad(),
      'num_hijos': intv('m03_num_hijos'),
      'hijos_menores_3': intv('m03_hijos_menores_3'),
    };

    // 4. Llamada al comparador individual vs conjunta
    final declaranteA = {
      'ingreso_integro_trabajo': num('m02_gross_income'),
      'seguridad_social': num('m02_social_security'),
      'retenciones': num('m02_withholdings'),
      'dividendos': num('m05_dividendos'),
      'intereses': num('m05_intereses'),
      // Mismas cifras que en la declaración individual, para que la
      // comparación individual/conjunta parta de la misma base.
      'ganancias_patrimoniales': num('m06_ganancias') +
          num('m07_ganancia_fondos') +
          num('m06_ganancias_cortas'),
      'perdidas_patrimoniales': num('m06_perdidas') +
          num('m07_perdida_fondos') +
          num('m06_perdidas_cortas'),
      'edad': edad,
    };

    final respComp = await http.post(
      Uri.parse('$base/calcular/comparar'),
      headers: {
        'Content-Type': 'application/json',
        ...await _cabeceraAuth(),
      },
      body: jsonEncode({
        'declarante_a': declaranteA,
        'declarante_b': conyuge,
        'unidad': unidad,
      }),
    );

    // 5. Combinar: resultado individual + comparación en un solo JSON
    final resultadoIndividual = jsonDecode(resp.body);
    if (respComp.statusCode == 200) {
      resultadoIndividual['comparacion'] = jsonDecode(respComp.body);
    }
    return jsonEncode(resultadoIndividual);
  } catch (e) {
    return '{"error": true, "mensaje": "$e"}';
  }
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

/// Cabecera de autenticación para la API de cálculo: el ID token de
/// Firebase del usuario que ha iniciado sesión (FirebaseAuth lo renueva solo
/// si ha caducado). Sin sesión no se envía y la API responde 401.
Future<Map<String, String>> _cabeceraAuth() async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  return (token == null || token.isEmpty)
      ? <String, String>{}
      : {'Authorization': 'Bearer $token'};
}
