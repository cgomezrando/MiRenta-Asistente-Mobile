// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// ============================================================
// Custom Action: mostrarMisDeclaraciones
// Lista las declaraciones guardadas del usuario. Tocar una la abre; el
// icono de papelera la elimina (con confirmación) de Firestore
// (colección 'declarations').
//
// PARÁMETROS: context (BuildContext)
// Include BuildContext: ON. Return Value: OFF.
// Paquetes: ninguno nuevo (cloud_firestore ya lo usa leerDeclaraciones).
// ============================================================

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

Future mostrarMisDeclaraciones(BuildContext context) async {
  const Color azul = Color(0xFF1B3A6B);
  const Color verde = Color(0xFF0F6E56);
  const Color verdeFondo = Color(0xFFE1F5EE);
  const Color crema = Color(0xFFFAFAF8);
  const Color textoSec = Color(0xFF6B7280);
  const Color textoPrin = Color(0xFF2C3E50);
  const Color borde = Color(0xFFE5E7EB);
  const Color rojo = Color(0xFFB3261E);

  String euro(double n) {
    final abs = n.abs();
    final partes = abs.toStringAsFixed(2).split('.');
    final entero = partes[0];
    final buffer = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
      buffer.write(entero[i]);
    }
    return '${buffer.toString()},${partes[1]} €';
  }

  String fecha(int ms) {
    if (ms == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // Leer las declaraciones
  final json = await leerDeclaraciones();
  Map<String, dynamic> data;
  try {
    data = jsonDecode(json);
  } catch (e) {
    data = {'error': true, 'mensaje': 'No se pudieron leer'};
  }

  final List declaraciones =
      (data['error'] != true) ? List.from(data['declaraciones'] ?? []) : [];

  // Confirmación antes de borrar: no se puede deshacer.
  Future<bool> confirmarBorrado(Map d) async {
    bool borrar = false;
    await showDialog(
      context: context,
      builder: (dc) => Dialog(
        // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: crema,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: azul,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Eliminar declaración',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Eliminar la declaración ${d['year']}?',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: textoPrin)),
                    const SizedBox(height: 8),
                    Text(
                      'Guardada el ${fecha(d['createdAt'] ?? 0)} · '
                      '${euro((d['result'] ?? 0).toDouble())} '
                      '${d['toRefund'] == true ? 'a devolver' : 'a pagar'}. '
                      'Se borrará para siempre.',
                      style: const TextStyle(
                          fontSize: 13.5, color: textoSec, height: 1.45),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(dc).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: azul),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('Cancelar',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: azul)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          borrar = true;
                          Navigator.of(dc).pop();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: rojo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('Eliminar',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return borrar;
  }

  await showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
          decoration: BoxDecoration(
            color: crema,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: azul,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mis declaraciones',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    InkWell(
                      onTap: () => Navigator.of(c).pop(),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              // Lista
              Flexible(
                child: declaraciones.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open, size: 40, color: textoSec),
                            SizedBox(height: 12),
                            Text('Aún no tienes declaraciones guardadas',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 14, color: textoSec)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(14),
                        itemCount: declaraciones.length,
                        itemBuilder: (context, i) {
                          final d = declaraciones[i] as Map;
                          final result = (d['result'] ?? 0).toDouble();
                          final aDevolver = d['toRefund'] == true;
                          final idDecl = d['id']?.toString() ?? '';
                          return InkWell(
                            onTap: () async {
                              Navigator.of(c).pop();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (cc) => const Center(
                                  child: CircularProgressIndicator(color: azul),
                                ),
                              );
                              final resultadoJson =
                                  await abrirDeclaracion(idDecl);
                              Navigator.of(context, rootNavigator: true).pop();
                              await mostrarInforme(context, resultadoJson);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: borde, width: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Declaración ${d['year']}',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: azul)),
                                        const SizedBox(height: 4),
                                        Text(fecha(d['createdAt'] ?? 0),
                                            style: const TextStyle(
                                                fontSize: 12, color: textoSec)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(euro(result),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: azul)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: aDevolver
                                              ? verdeFondo
                                              : const Color(0xFFFAEEDA),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                            aDevolver
                                                ? 'A devolver'
                                                : 'A pagar',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: aDevolver
                                                    ? verde
                                                    : const Color(0xFF854F0B))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  // Eliminar
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete_outline,
                                        color: textoSec, size: 22),
                                    onPressed: () async {
                                      if (!await confirmarBorrado(d)) return;
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('declarations')
                                            .doc(idDecl)
                                            .delete();
                                        setState(
                                            () => declaraciones.removeAt(i));
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                'No se ha podido eliminar: $e'),
                                            backgroundColor: rojo,
                                          ));
                                        }
                                      }
                                    },
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: textoSec, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
