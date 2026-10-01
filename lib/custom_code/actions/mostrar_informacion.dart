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
// Custom Action: mostrarInformacion
// Muestra un diálogo con el menú de Información y sus secciones:
//   1. Cómo funciona la app
//   2. Aviso importante (no es asesoramiento fiscal)
//   3. Política de privacidad
//   4. Términos y condiciones
//   5. Contacto
//
// NOTA LEGAL: estos textos son BORRADORES orientativos. Antes de
// publicar, conviene que un abogado especializado en protección
// de datos los revise.
//
// Include BuildContext: ON
// ============================================================

Future<void> mostrarInformacion(BuildContext context) async {
  const azul = Color(0xFF1B3A6B);
  const crema = Color(0xFFFAFAF8);
  const textoSec = Color(0xFF6B7280);

  // Datos del responsable
  const responsable = 'CARLOS GOMEZ RANDO';
  const correo = 'cgrandodeveloper@gmail.com';
  const nombreApp = 'MiRenta Asistente';

  // Vista actual: 'menu' | 'como' | 'aviso' | 'privacidad' | 'terminos' | 'contacto'
  String vista = 'menu';

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        // Párrafo de texto reutilizable
        Widget parrafo(String texto, {bool negrita = false}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Colors.black87,
                fontWeight: negrita ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          );
        }

        Widget subtitulo(String texto) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: azul)),
          );
        }

        // Cabecera con flecha atrás + título
        Widget cabecera(String titulo) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: azul),
                onPressed: () => setState(() => vista = 'menu'),
              ),
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: azul)),
              ),
            ],
          );
        }

        // Opción del menú principal
        Widget opcionMenu(IconData icono, String titulo, String destino) {
          return InkWell(
            onTap: () => setState(() => vista = destino),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: azul.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(icono, color: azul, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ),
                  const Icon(Icons.chevron_right, color: textoSec, size: 20),
                ],
              ),
            ),
          );
        }

        // --- MENÚ PRINCIPAL ---
        Widget vistaMenu() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text('Información',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: azul)),
              ),
              const SizedBox(height: 8),
              opcionMenu(Icons.help_outline, 'Cómo funciona la app', 'como'),
              opcionMenu(
                  Icons.warning_amber_outlined, 'Aviso importante', 'aviso'),
              opcionMenu(
                  Icons.lock_outline, 'Política de privacidad', 'privacidad'),
              opcionMenu(Icons.description_outlined, 'Términos y condiciones',
                  'terminos'),
              opcionMenu(Icons.mail_outline, 'Contacto', 'contacto'),
            ],
          );
        }

        // --- 1. CÓMO FUNCIONA ---
        Widget vistaComo() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera('Cómo funciona'),
              const SizedBox(height: 8),
              parrafo(
                  '$nombreApp es una herramienta que te ayuda a obtener una estimación de tu declaración de la renta (IRPF) a partir de la información que tú introduces.'),
              subtitulo('Paso a paso'),
              parrafo(
                  '1. Responde a las preguntas del cuestionario sobre tus ingresos, situación familiar y otras circunstancias.'),
              parrafo(
                  '2. La aplicación calcula una estimación de tu resultado (a pagar o a devolver).'),
              parrafo(
                  '3. Puedes guardar tus datos para revisarlos o continuar más adelante.'),
              subtitulo('Ten en cuenta'),
              parrafo(
                  'El resultado es una estimación orientativa. Cuantos más datos aportes y más precisos sean, más se aproximará la estimación a tu declaración real.'),
            ],
          );
        }

        // --- 2. AVISO IMPORTANTE ---
        Widget vistaAviso() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera('Aviso importante'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE6C86E)),
                ),
                child: parrafo(
                    '$nombreApp ofrece una ESTIMACIÓN orientativa y no constituye asesoramiento fiscal, legal ni contable.',
                    negrita: true),
              ),
              parrafo(
                  'La estimación que proporciona esta aplicación no sustituye a la declaración oficial del IRPF ante la Agencia Tributaria (AEAT), ni al asesoramiento de un profesional cualificado.'),
              parrafo(
                  'Esta aplicación no presenta ninguna declaración ante la AEAT ni se comunica con ella. Es responsabilidad exclusiva del usuario la presentación de su declaración real y la veracidad de los datos declarados.'),
              parrafo(
                  'Los cálculos se basan en la normativa vigente conocida y en los datos introducidos por el usuario. Pueden existir circunstancias particulares no contempladas que hagan que el resultado real difiera de la estimación.'),
              parrafo(
                  'Antes de tomar cualquier decisión con trascendencia económica o fiscal, te recomendamos consultar con un asesor fiscal o gestor cualificado.'),
              parrafo(
                  'El responsable de la aplicación no se hace responsable de las decisiones tomadas por el usuario basándose en las estimaciones ofrecidas.'),
            ],
          );
        }

        // --- 3. POLÍTICA DE PRIVACIDAD ---
        Widget vistaPrivacidad() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera('Política de privacidad'),
              const SizedBox(height: 8),
              subtitulo('Responsable del tratamiento'),
              parrafo('Responsable: $responsable.\nContacto: $correo'),
              subtitulo('Qué datos tratamos'),
              parrafo(
                  'Tratamos los datos que tú introduces para calcular tu estimación: datos identificativos (nombre, fecha de nacimiento, correo), y datos económicos y personales necesarios para el cálculo del IRPF (ingresos, situación familiar, y otros que puedan incluir información sensible como el grado de discapacidad, si decides aportarlo).'),
              subtitulo('Con qué finalidad'),
              parrafo(
                  'Los datos se utilizan únicamente para calcular tu estimación de la renta, guardar tus declaraciones para que puedas consultarlas, y gestionar tu cuenta de usuario.'),
              subtitulo('Base legal'),
              parrafo(
                  'El tratamiento se basa en tu consentimiento, que otorgas al registrarte y utilizar la aplicación, y en la ejecución del servicio que solicitas.'),
              subtitulo('Dónde se guardan'),
              parrafo(
                  'Los datos se almacenan en servicios de Google Firebase (Firestore y Authentication), que aplican medidas de seguridad y cifrado. Los datos pueden alojarse en servidores dentro del Espacio Económico Europeo o en países con garantías adecuadas conforme al RGPD.'),
              subtitulo('Cuánto tiempo'),
              parrafo(
                  'Conservamos tus datos mientras mantengas tu cuenta activa. Puedes solicitar su eliminación en cualquier momento.'),
              subtitulo('Tus derechos'),
              parrafo(
                  'Tienes derecho a acceder, rectificar, suprimir, limitar u oponerte al tratamiento de tus datos, así como a la portabilidad de los mismos. Para ejercerlos, escribe a $correo. También puedes presentar una reclamación ante la Agencia Española de Protección de Datos (www.aepd.es).'),
              subtitulo('Terceros'),
              parrafo(
                  'No vendemos ni cedemos tus datos a terceros con fines comerciales. Solo se utilizan los proveedores tecnológicos necesarios para el funcionamiento de la app (Google Firebase).'),
            ],
          );
        }

        // --- 4. TÉRMINOS Y CONDICIONES ---
        Widget vistaTerminos() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera('Términos y condiciones'),
              const SizedBox(height: 8),
              subtitulo('1. Objeto'),
              parrafo(
                  'Estos términos regulan el uso de la aplicación $nombreApp, cuyo responsable es $responsable. El uso de la aplicación implica la aceptación de estas condiciones.'),
              subtitulo('2. Servicio ofrecido'),
              parrafo(
                  'La aplicación ofrece una estimación orientativa del IRPF. No constituye asesoramiento fiscal ni presenta declaraciones ante la AEAT. Consulta el apartado "Aviso importante".'),
              subtitulo('3. Uso responsable'),
              parrafo(
                  'El usuario se compromete a introducir datos veraces y a utilizar la aplicación conforme a la ley. El usuario es responsable de la custodia de sus credenciales de acceso.'),
              subtitulo('4. Limitación de responsabilidad'),
              parrafo(
                  'El responsable no garantiza que las estimaciones coincidan con el resultado real de la declaración y no será responsable de las decisiones que el usuario tome basándose en ellas. La aplicación se ofrece "tal cual", sin garantías de exactitud absoluta.'),
              subtitulo('5. Propiedad intelectual'),
              parrafo(
                  'Los contenidos, el diseño y el software de la aplicación son propiedad de su titular. Queda prohibida su reproducción sin autorización.'),
              subtitulo('6. Modificaciones'),
              parrafo(
                  'El responsable puede modificar estos términos y las funcionalidades de la aplicación. Los cambios se comunicarán a través de la propia aplicación.'),
              subtitulo('7. Legislación aplicable'),
              parrafo(
                  'Estos términos se rigen por la legislación española. Para cualquier controversia, las partes se someten a los juzgados y tribunales que correspondan conforme a la ley.'),
            ],
          );
        }

        // --- 5. CONTACTO ---
        Widget vistaContacto() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cabecera('Contacto'),
              const SizedBox(height: 8),
              parrafo(
                  'Si tienes dudas, sugerencias o quieres ejercer tus derechos de protección de datos, puedes escribirnos:'),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: azul.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, color: azul, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(correo,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: azul)),
                    ),
                  ],
                ),
              ),
              parrafo(
                  'Responsable: $responsable\nProcuramos responder en el menor plazo posible.'),
            ],
          );
        }

        Widget contenido;
        switch (vista) {
          case 'como':
            contenido = vistaComo();
            break;
          case 'aviso':
            contenido = vistaAviso();
            break;
          case 'privacidad':
            contenido = vistaPrivacidad();
            break;
          case 'terminos':
            contenido = vistaTerminos();
            break;
          case 'contacto':
            contenido = vistaContacto();
            break;
          default:
            contenido = vistaMenu();
        }

        return Dialog(
          // Márgenes laterales pequeños: en iPhone aprovecha el ancho.
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: crema,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
}
