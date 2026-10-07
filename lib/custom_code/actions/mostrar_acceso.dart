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
// Custom Action: mostrarAcceso
// Muestra un diálogo de acceso con tres vistas integradas:
//   1. Elegir (Iniciar sesión / Crear cuenta)
//   2. Iniciar sesión (correo + contraseña)
//   3. Crear cuenta (correo, contraseña, nombre, fecha de nacimiento)
// Gestiona todo internamente usando Firebase Auth y Firestore.
// Al terminar con éxito, cierra el diálogo (el usuario queda logueado).
//
// Include BuildContext: ON
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> mostrarAcceso(BuildContext context) async {
  const azul = Color(0xFF1B3A6B);
  const crema = Color(0xFFFAFAF8);
  const textoSec = Color(0xFF6B7280);
  const oro = Color(0xFFC9A961);

  // Vista actual: 'elegir' | 'login' | 'registro'
  String vista = 'elegir';

  // Controllers
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  DateTime? fechaNac;

  String mensajeError = '';
  bool cargando = false;

  // --- Validación de contraseña ---
  String validarPass(String p) {
    if (p.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(p)) {
      return 'La contraseña debe incluir al menos una letra.';
    }
    if (!RegExp(r'[0-9]').hasMatch(p)) {
      return 'La contraseña debe incluir al menos un número.';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]').hasMatch(p)) {
      return 'La contraseña debe incluir al menos un carácter especial (! @ # \$ % & *).';
    }
    return '';
  }

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        // Diálogo de confirmación (éxito) mostrado tras login o registro
        Future<void> mostrarConfirmacion(String titulo, String mensaje) async {
          await showDialog(
            context: context,
            builder: (dctx) => Dialog(
              // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              backgroundColor: crema,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF2E7D32), size: 48),
                    const SizedBox(height: 16),
                    Text(titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: azul)),
                    const SizedBox(height: 8),
                    Text(mensaje,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azul,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      onPressed: () => Navigator.pop(dctx),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Campo de texto reutilizable
        Widget campo(String label, TextEditingController ctrl,
            {bool password = false, TextInputType? tipo}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: ctrl,
              obscureText: password,
              keyboardType: tipo,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: textoSec, fontSize: 13),
                floatingLabelStyle: const TextStyle(color: azul, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                // Borde visible SIEMPRE (no solo al hacer clic)
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: azul, width: 1.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: azul, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: azul, width: 1.5),
                ),
              ),
            ),
          );
        }

        Widget botonPrincipal(String texto, VoidCallback onTap) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: azul,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: cargando ? null : onTap,
            child: cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(texto,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          );
        }

        Widget errorWidget() {
          if (mensajeError.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(mensajeError,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          );
        }

        // --- VISTA: ELEGIR ---
        Widget vistaElegir() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bienvenido',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: azul)),
              const SizedBox(height: 6),
              const Text(
                  'Accede a tu cuenta para guardar tus declaraciones y continuarlas cuando quieras.',
                  style: TextStyle(fontSize: 13, color: textoSec)),
              const SizedBox(height: 24),
              botonPrincipal('Iniciar sesión', () {
                setState(() {
                  vista = 'login';
                  mensajeError = '';
                });
              }),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: azul,
                  side: const BorderSide(color: azul),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () {
                  setState(() {
                    vista = 'registro';
                    mensajeError = '';
                  });
                },
                child: const Text('Crear cuenta nueva',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        }

        // --- VISTA: LOGIN ---
        Widget vistaLogin() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: azul),
                  onPressed: () => setState(() {
                    vista = 'elegir';
                    mensajeError = '';
                  }),
                ),
                const Text('Iniciar sesión',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: azul)),
              ]),
              const SizedBox(height: 16),
              campo('Correo electrónico', emailCtrl,
                  tipo: TextInputType.emailAddress),
              campo('Contraseña', passCtrl, password: true),
              errorWidget(),
              botonPrincipal('Entrar', () async {
                setState(() {
                  cargando = true;
                  mensajeError = '';
                });
                final correo = emailCtrl.text.trim();
                final pass = passCtrl.text;
                if (correo.isEmpty || pass.isEmpty) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Introduce tu correo y tu contraseña.';
                  });
                  return;
                }
                try {
                  final cred = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                          email: correo, password: pass);
                  // Recuperar el nombre del usuario (de Auth o de Firestore)
                  String nombre = cred.user?.displayName ?? '';
                  if (nombre.isEmpty && cred.user != null) {
                    try {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(cred.user!.uid)
                          .get();
                      nombre = (doc.data()?['nombreCompleto'] ?? '') as String;
                    } catch (_) {}
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await mostrarConfirmacion(
                    'Sesión iniciada',
                    nombre.isNotEmpty
                        ? 'Bienvenido de nuevo, $nombre.'
                        : 'Has iniciado sesión correctamente.',
                  );
                } on FirebaseAuthException catch (e) {
                  String msg;
                  switch (e.code) {
                    case 'user-not-found':
                    case 'wrong-password':
                    case 'invalid-credential':
                      msg = 'El correo o la contraseña no son correctos.';
                      break;
                    case 'invalid-email':
                      msg = 'El correo electrónico no es válido.';
                      break;
                    case 'too-many-requests':
                      msg =
                          'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
                      break;
                    default:
                      msg = 'No se pudo iniciar sesión.';
                  }
                  setState(() {
                    cargando = false;
                    mensajeError = msg;
                  });
                } catch (e) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Ha ocurrido un error. Inténtalo de nuevo.';
                  });
                }
              }),
            ],
          );
        }

        // --- VISTA: REGISTRO ---
        Widget vistaRegistro() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: azul),
                  onPressed: () => setState(() {
                    vista = 'elegir';
                    mensajeError = '';
                  }),
                ),
                const Flexible(
                  child: Text('Crear cuenta nueva',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: azul)),
                ),
              ]),
              const SizedBox(height: 16),
              campo('Nombre completo', nombreCtrl),
              campo('Correo electrónico', emailCtrl,
                  tipo: TextInputType.emailAddress),
              campo('Contraseña', passCtrl, password: true),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                    'Mínimo 8 caracteres, con letras, números y un carácter especial.',
                    style: TextStyle(fontSize: 11, color: textoSec)),
              ),
              // Selector de fecha de nacimiento
              InkWell(
                onTap: () async {
                  final elegida = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime(1990, 1, 1),
                    firstDate: DateTime(1910),
                    lastDate: DateTime.now(),
                    locale: const Locale('es', 'ES'),
                  );
                  if (elegida != null) setState(() => fechaNac = elegida);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: azul, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: textoSec),
                      const SizedBox(width: 12),
                      Text(
                        fechaNac == null
                            ? 'Fecha de nacimiento'
                            : '${fechaNac!.day.toString().padLeft(2, '0')}/${fechaNac!.month.toString().padLeft(2, '0')}/${fechaNac!.year}',
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                fechaNac == null ? textoSec : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              errorWidget(),
              botonPrincipal('Crear cuenta', () async {
                setState(() {
                  cargando = true;
                  mensajeError = '';
                });
                final correo = emailCtrl.text.trim();
                final pass = passCtrl.text;
                final nombre = nombreCtrl.text.trim();

                // Validaciones
                if (nombre.isEmpty) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Introduce tu nombre completo.';
                  });
                  return;
                }
                if (correo.isEmpty ||
                    !correo.contains('@') ||
                    !correo.contains('.')) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Introduce un correo electrónico válido.';
                  });
                  return;
                }
                final errPass = validarPass(pass);
                if (errPass.isNotEmpty) {
                  setState(() {
                    cargando = false;
                    mensajeError = errPass;
                  });
                  return;
                }
                if (fechaNac == null) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Selecciona tu fecha de nacimiento.';
                  });
                  return;
                }

                // Crear cuenta
                try {
                  // 1. Crear el usuario en Firebase Auth (lo esencial)
                  final cred = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                          email: correo, password: pass);
                  final uid = cred.user?.uid;

                  // 2. Operaciones secundarias (nombre y perfil en Firestore).
                  // Si alguna falla, NO es un error crítico: la cuenta ya
                  // está creada. Por eso van en su propio try/catch que no
                  // muestra error al usuario.
                  try {
                    await cred.user?.updateDisplayName(nombre);
                    final fechaStr =
                        '${fechaNac!.year}-${fechaNac!.month.toString().padLeft(2, '0')}-${fechaNac!.day.toString().padLeft(2, '0')}';
                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'nombreCompleto': nombre,
                        'fechaNacimiento': fechaStr,
                        'email': correo,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                  } catch (_) {
                    // El perfil no se pudo guardar, pero la cuenta existe.
                    // Continuamos como éxito.
                  }

                  // 3. Éxito: cerrar y confirmar
                  if (ctx.mounted) Navigator.pop(ctx);
                  await mostrarConfirmacion(
                    'Cuenta creada',
                    'Tu cuenta se ha creado correctamente, $nombre.',
                  );
                } on FirebaseAuthException catch (e) {
                  String msg;
                  switch (e.code) {
                    case 'email-already-in-use':
                      msg =
                          'Ya existe una cuenta con ese correo. Inicia sesión.';
                      break;
                    case 'invalid-email':
                      msg = 'El correo electrónico no es válido.';
                      break;
                    case 'weak-password':
                      msg = 'La contraseña es demasiado débil.';
                      break;
                    default:
                      msg = 'No se pudo crear la cuenta.';
                  }
                  setState(() {
                    cargando = false;
                    mensajeError = msg;
                  });
                } catch (e) {
                  setState(() {
                    cargando = false;
                    mensajeError = 'Ha ocurrido un error. Inténtalo de nuevo.';
                  });
                }
              }),
            ],
          );
        }

        Widget contenido;
        if (vista == 'login') {
          contenido = vistaLogin();
        } else if (vista == 'registro') {
          contenido = vistaRegistro();
        } else {
          contenido = vistaElegir();
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
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botón X para cerrar (siempre visible)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: textoSec),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  contenido,
                ],
              ),
            ),
          ),
        );
      });
    },
  );

  // Al cerrarse el diálogo, devolver si el usuario quedó logueado
  return FirebaseAuth.instance.currentUser != null;
}
