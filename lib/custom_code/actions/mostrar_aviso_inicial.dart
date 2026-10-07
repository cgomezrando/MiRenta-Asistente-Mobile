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
// Custom Action: mostrarAvisoInicial
// Muestra un aviso suave e informativo la PRIMERA VEZ que el
// usuario accede tras su primer login. El estado "ya visto" se
// guarda en el documento del usuario en Firestore (ligado a su
// cuenta, no al dispositivo), así no le vuelve a salir aunque
// entre desde otro dispositivo.
//
// Si no hay usuario logueado, no muestra nada.
//
// Include BuildContext: ON
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> mostrarAvisoInicial(BuildContext context) async {
  const azul = Color(0xFF1B3A6B);
  const crema = Color(0xFFFAFAF8);
  const textoSec = Color(0xFF6B7280);

  // Debe haber un usuario logueado para ligar el aviso a su cuenta
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // Comprobar en Firestore si el usuario ya vio el aviso
  try {
    final doc = await docRef.get();
    final yaVisto = (doc.data()?['avisoPrivacidadVisto'] ?? false) as bool;
    if (yaVisto) return;
  } catch (_) {
    // Si falla la lectura, por prudencia mostramos el aviso igualmente
  }

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: crema,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: azul.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.lock_outline, color: azul, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Tu privacidad es importante',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: azul),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Antes de empezar, te recomendamos conocer cómo tratamos y protegemos tu información.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Los datos que introduzcas se usan únicamente para calcular tu estimación. Puedes consultar en cualquier momento nuestra política de privacidad y las medidas de seguridad en el apartado de Información.',
                  style: TextStyle(fontSize: 13, color: textoSec, height: 1.45),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    try {
                      await docRef.set({'avisoPrivacidadVisto': true},
                          SetOptions(merge: true));
                    } catch (_) {}
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Entendido, continuar',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: azul),
                  onPressed: () async {
                    try {
                      await docRef.set({'avisoPrivacidadVisto': true},
                          SetOptions(merge: true));
                    } catch (_) {}
                    if (ctx.mounted) Navigator.pop(ctx);
                    // Cuando tengas la seccion de Informacion montada,
                    // abrela aqui. Por ejemplo:
                    // await mostrarInformacion(context);
                  },
                  child: const Text('Leer la política de privacidad',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
