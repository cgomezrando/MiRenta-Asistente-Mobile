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
import '/app_state.dart';
import '/flutter_flow/uploaded_file.dart';
import 'package:flutter/services.dart';

Future showInterviewDialog(BuildContext context) async {
  const Color primaryColor = Color(0xFF1B3A6B);
  const Color secondaryColor = Color(0xFF7BA9D0);
  const Color accentGold = Color(0xFFC9A961);
  const Color bgCream = Color(0xFFFAFAF8);
  const Color textPrimary = Color(0xFF2C3E50);
  const Color textSecondary = Color(0xFF6B7280);
  const Color borderColor = Color(0xFFE5E7EB);

  String? selectedOption;
  Set<String> multiSelected = {};
  DateTime? selectedDate;
  final TextEditingController textController = TextEditingController();
  bool showHelp = false;
  String? idPrecargado;
  // Texto de procedencia cuando el importe de la pregunta actual viene de
  // un documento importado (answer__origen_<id>): la pregunta pasa a ser
  // una confirmación del valor.
  String origenImportado = '';
  // Enunciado alternativo cuando un documento importado cambia el sentido
  // de la pregunta (p. ej. trabajo en el extranjero cuando Hacienda ya trae
  // el salario con la parte exenta descontada).
  String tituloAlternativo = '';
  String aclaracionAlternativa = '';

  // Paso de importación: los documentos se eligen todos primero y se
  // analizan juntos con "Analizar documentos", en el orden correcto
  // (AEAT, DEGIRO, IBKR, plantilla), para que no importe en qué orden los
  // haya elegido el usuario.
  FFUploadedFile? docAeat;
  FFUploadedFile? docDegiro;
  FFUploadedFile? docIbkr;
  FFUploadedFile? docPlantilla;
  final Map<String, String> docEstado = {};
  bool analizando = false;

  // Un unico sitio con el ejercicio que se declara. Al cambiar de año se
  // toca aqui y no en cada llamada.
  const int anioEjercicioActual = 2025;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final visibles = FFAppState().visibleQuestions;
          final currentId = FFAppState().currentQuestionId;
          final idx = visibles.indexWhere((q) => q.id == currentId);
          if (idx == -1) {
            return Dialog(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay preguntas cargadas.'),
              ),
            );
          }
          final question = visibles[idx];

          // En iPhone (ancho < 500) márgenes y rellenos más pequeños y un
          // título algo menor, para que todo quepa sin cortes.
          final pantalla = MediaQuery.of(ctx).size;
          final estrecho = pantalla.width < 500;
          final rel = estrecho ? 16.0 : 24.0;
          final altoMaxDialogo =
              pantalla.height * 0.92 < 720 ? pantalla.height * 0.92 : 720.0;

          // Precargar la respuesta guardada al mostrar una pregunta nueva
          if (idPrecargado != question.id) {
            idPrecargado = question.id;
            origenImportado = '';
            tituloAlternativo = '';
            aclaracionAlternativa = '';
            () async {
              final origen = await getAnswer('_origen_${question.id}');
              if (origen.isNotEmpty) {
                origenImportado = origen;
                setState(() {});
              }
              if (question.id == 'm02_foreign_work') {
                final origenSalario =
                    await getAnswer('_origen_m02_gross_income');
                final salario = await getAnswer('m02_gross_income');
                if (origenSalario.isNotEmpty && salario.isNotEmpty) {
                  tituloAlternativo =
                      '¿Trabajaste en el extranjero días que NO estén ya '
                      'descontados de los ${_numEs(_leerNumeroEs(salario) ?? 0.0)} € '
                      'que constan en Hacienda?';
                  aclaracionAlternativa =
                      'Si tu empresa ya aplicó la exención del artículo 7p, '
                      'esos días están descontados en esa cifra: responde '
                      'No. Responde Sí solo si hubo más días fuera que no '
                      'se han tenido en cuenta.';
                  setState(() {});
                }
              }
              final guardada = await getAnswer(question.id);
              if (guardada != null && guardada.toString().isNotEmpty) {
                final valor = guardada.toString();
                switch (question.controlType) {
                  case 'yesNo':
                  case 'singleSelect':
                  case 'dropdown':
                    selectedOption = valor;
                    break;
                  case 'multiSelect':
                    multiSelected = valor.split(',').toSet();
                    break;
                  case 'date':
                    try {
                      final p = valor.split('-');
                      selectedDate = DateTime(
                          int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                    } catch (e) {}
                    break;
                  case 'amount':
                    final n = _leerNumeroEs(valor);
                    textController.text = n == null ? valor : _numEs(n);
                    break;
                  case 'integer':
                  case 'text':
                    textController.text = valor;
                    break;
                }
                setState(() {});
              }
            }();
          }
          final hasPrevious = FFAppState().navigationHistory.isNotEmpty;
          final isLast = idx >= visibles.length - 1;
          final activeModules = FFAppState().activeModules;
          final currentModuleIdx = activeModules.indexOf(question.module);

          Widget controlWidget;
          switch (question.controlType) {
            case 'yesNo':
              controlWidget = Row(
                children: [
                  for (final opt in ['Sí', 'No']) ...[
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => selectedOption = opt),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: selectedOption == opt
                                ? secondaryColor.withOpacity(0.15)
                                : Colors.white,
                            border: Border.all(
                              color: selectedOption == opt
                                  ? primaryColor
                                  : borderColor,
                              width: selectedOption == opt ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(opt,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary)),
                          ),
                        ),
                      ),
                    ),
                    if (opt == 'Sí') SizedBox(width: 12),
                  ],
                ],
              );
              break;

            case 'integer':
              controlWidget = TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16, color: textPrimary),
                decoration: _inputDecoration(
                    'Introduce un número', borderColor, primaryColor),
              );
              break;

            case 'amount':
              controlWidget = TextField(
                controller: textController,
                inputFormatters: [_FormatoMilesEs()],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 16, color: textPrimary),
                decoration: _inputDecoration('0,00', borderColor, primaryColor)
                    .copyWith(suffixText: '€'),
              );
              break;

            case 'singleSelect':
              controlWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: question.options.map((opt) {
                  final isSelected = selectedOption == opt;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => selectedOption = opt),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? secondaryColor.withOpacity(0.15)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected ? primaryColor : secondaryColor,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(opt,
                                  style: TextStyle(
                                      fontSize: 14, color: textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
              break;

            case 'multiSelect':
              controlWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: question.options.map((opt) {
                  final isSelected = multiSelected.contains(opt);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() {
                        if (isSelected) {
                          multiSelected.remove(opt);
                        } else {
                          multiSelected.add(opt);
                        }
                      }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? secondaryColor.withOpacity(0.15)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 18,
                              color: isSelected ? primaryColor : secondaryColor,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(opt,
                                  style: TextStyle(
                                      fontSize: 14, color: textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
              break;

            case 'date':
              controlWidget = InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: secondaryColor),
                      SizedBox(width: 10),
                      Text(
                        selectedDate == null
                            ? 'Selecciona una fecha'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
                        style: TextStyle(
                            fontSize: 15,
                            color: selectedDate == null
                                ? textSecondary
                                : textPrimary),
                      ),
                    ],
                  ),
                ),
              );
              break;

            case 'text':
              controlWidget = TextField(
                controller: textController,
                style: TextStyle(fontSize: 16, color: textPrimary),
                decoration:
                    _inputDecoration('Escribe aquí', borderColor, primaryColor),
              );
              break;

            case 'dropdown':
              controlWidget = Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: selectedOption != null ? primaryColor : borderColor,
                    width: selectedOption != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: (selectedOption != null &&
                          question.options.contains(selectedOption))
                      ? selectedOption
                      : null,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  underline: SizedBox(),
                  hint: Text('Selecciona una opción',
                      style: TextStyle(color: textSecondary)),
                  style: TextStyle(fontSize: 15, color: textPrimary),
                  items: question.options.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt, style: TextStyle(color: textPrimary)),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedOption = v;
                    });
                  },
                ),
              );
              break;
            case 'perdidasPendientes':
              controlWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trending_down,
                            size: 20, color: primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Las pérdidas se compensan empezando por las más antiguas y caducan a los cuatro años, así que hay que indicar de qué ejercicio viene cada una.',
                            style: TextStyle(
                                fontSize: 14, color: textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await gestionarPerdidasPendientes(
                          context, anioEjercicioActual);
                      setState(() {});
                    },
                    icon: Icon(Icons.edit_calendar,
                        size: 18, color: Colors.white),
                    label: Text('Indicar pérdidas por año',
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
              break;

            case 'inmuebles':
              controlWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.home_work_outlined,
                            size: 20, color: primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Añade aquí todos tus inmuebles: los que tienes alquilados y las segundas viviendas a tu disposición. No incluyas tu vivienda habitual.',
                            style: TextStyle(
                                fontSize: 14, color: textPrimary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      await gestionarInmuebles(context);
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_home_outlined,
                              size: 20, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Gestionar mis inmuebles',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
              break;
            case 'datosFiscalesUpload':
              Widget slot({
                required String clave,
                required String titulo,
                required String subtitulo,
                required IconData icono,
                required FFUploadedFile? doc,
                required Future<FFUploadedFile?> Function() elegir,
                required void Function(FFUploadedFile?) fijar,
                List<Widget> enlaces = const [],
              }) {
                final estado = docEstado[clave] ?? '';
                final analizado = estado.isNotEmpty;
                final elegido = doc != null;
                final Color borde = analizado
                    ? Color(0xFF2E7D32)
                    : (elegido ? primaryColor : borderColor);
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: analizado
                          ? Color(0xFF2E7D32).withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: borde, width: elegido ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          analizado
                              ? Icons.check_circle
                              : (elegido ? Icons.check_circle_outline : icono),
                          size: 22,
                          color: analizado
                              ? Color(0xFF2E7D32)
                              : (elegido ? primaryColor : textSecondary),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(titulo,
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary)),
                              SizedBox(height: 2),
                              Text(
                                analizado
                                    ? estado
                                    : (elegido
                                        ? (doc?.name ?? 'Archivo elegido')
                                        : subtitulo),
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: analizado
                                        ? Color(0xFF2E7D32)
                                        : textSecondary,
                                    height: 1.3),
                              ),
                              if (!elegido && !analizado && enlaces.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Wrap(
                                    spacing: 14,
                                    runSpacing: 4,
                                    children: enlaces,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        if (!analizando)
                          InkWell(
                            onTap: () async {
                              if (elegido) {
                                fijar(null);
                                docEstado.remove(clave);
                                setState(() {});
                                return;
                              }
                              final archivo = await elegir();
                              if (archivo != null) {
                                fijar(archivo);
                                docEstado.remove(clave);
                                setState(() {});
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: elegido ? Colors.white : primaryColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: primaryColor),
                              ),
                              child: Text(
                                elegido ? 'Quitar' : 'Elegir',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        elegido ? primaryColor : Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              Widget enlace(
                      String texto, IconData icono, VoidCallback alPulsar) =>
                  InkWell(
                    onTap: alPulsar,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icono, size: 14, color: primaryColor),
                        SizedBox(width: 4),
                        Text(texto,
                            style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );

              final hayDocs = docAeat != null ||
                  docDegiro != null ||
                  docIbkr != null ||
                  docPlantilla != null;

              Future<void> analizarTodo() async {
                if (analizando || !hayDocs) return;
                analizando = true;
                setState(() {});
                var hayBroker = false;
                // Orden fijo: AEAT (datos base), DEGIRO antes que IBKR (los
                // traspasos DEGIRO -> IBKR necesitan el coste original) y la
                // plantilla al final.
                if (docAeat != null) {
                  final r = await procesarDatosFiscales(
                      context, docAeat!, anioEjercicioActual);
                  if (r.startsWith('true')) {
                    final n = r.split('|').length > 1 ? r.split('|')[1] : '0';
                    docEstado['aeat'] = 'Analizado: $n campos rellenados';
                  } else {
                    docEstado['aeat'] = 'No se ha aplicado';
                  }
                }
                if (docDegiro != null) {
                  final r = await procesarInformeDegiro(
                      context, docDegiro!, anioEjercicioActual);
                  docEstado['degiro'] = r.startsWith('true')
                      ? 'Analizado y combinado con tus otros brókeres'
                      : 'No se ha guardado';
                  hayBroker = hayBroker || r.startsWith('true');
                }
                if (docIbkr != null) {
                  final r = await procesarExtractoIBKR(
                      context, docIbkr!, anioEjercicioActual);
                  docEstado['ibkr'] = r.startsWith('true')
                      ? 'Analizado y combinado con tus otros brókeres'
                      : 'No se ha guardado';
                  hayBroker = hayBroker || r.startsWith('true');
                }
                if (docPlantilla != null) {
                  await procesarCsvGenerico(
                      context, docPlantilla!, anioEjercicioActual);
                  docEstado['plantilla'] = 'Analizado';
                  hayBroker = true;
                }
                // Ventas que constan en Hacienda (bancos españoles) y que
                // no vienen en ningún extracto: se piden ISIN, acciones y
                // fecha y coste de compra, y se suman al resto.
                final vh =
                    await completarVentasHacienda(context, anioEjercicioActual);
                if (vh.startsWith('true')) {
                  final n = vh.split('|').length > 1 ? vh.split('|')[1] : '0';
                  docEstado['aeat'] =
                      '${docEstado['aeat'] ?? 'Analizado'} · $n venta(s) de Hacienda calculadas';
                  hayBroker = true;
                }
                await saveAnswer(question.id, 'importado');
                analizando = false;
                setState(() {});
                if (hayBroker && context.mounted) {
                  await mostrarResumenBolsa(context);
                }
              }

              controlWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor),
                    ),
                    child: Text(
                      'Elige todos los documentos que tengas y pulsa '
                      '"Analizar documentos": se leen juntos y se combinan. '
                      'Los datos fiscales de la AEAT traen ingresos, '
                      'retenciones e intereses; los extractos de bróker, las '
                      'ganancias, dividendos y comisiones. Después revisarás '
                      'cada importe en el cuestionario.',
                      style: TextStyle(
                          fontSize: 13.5, color: textPrimary, height: 1.4),
                    ),
                  ),
                  SizedBox(height: 16),
                  slot(
                    clave: 'aeat',
                    titulo: 'Datos fiscales de la AEAT (PDF)',
                    subtitulo:
                        'Ingresos, retenciones, intereses, plan de pensiones y ventas que comunica tu banco.',
                    icono: Icons.account_balance_outlined,
                    doc: docAeat,
                    elegir: elegirArchivoPdf,
                    fijar: (d) => docAeat = d,
                    enlaces: [
                      enlace('Ir a la web de la AEAT', Icons.open_in_new,
                          () => launchURL(_urlDatosFiscalesAeat)),
                      enlace(
                          '¿Cómo lo descargo?',
                          Icons.help_outline,
                          () => _ayudaDocumento(
                              context, 'aeat', anioEjercicioActual)),
                    ],
                  ),
                  slot(
                    clave: 'ibkr',
                    titulo: 'Interactive Brokers (CSV)',
                    subtitulo:
                        'Activity Statement del ejercicio $anioEjercicioActual en CSV y en inglés.',
                    icono: Icons.upload_file,
                    doc: docIbkr,
                    elegir: elegirArchivoCsv,
                    fijar: (d) => docIbkr = d,
                    enlaces: [
                      enlace(
                          '¿Qué informe necesito?',
                          Icons.help_outline,
                          () => _ayudaDocumento(
                              context, 'ibkr', anioEjercicioActual)),
                    ],
                  ),
                  slot(
                    clave: 'degiro',
                    titulo: 'DEGIRO (PDF)',
                    subtitulo: 'Informe Anual $anioEjercicioActual.',
                    icono: Icons.picture_as_pdf,
                    doc: docDegiro,
                    elegir: elegirArchivoPdf,
                    fijar: (d) => docDegiro = d,
                    enlaces: [
                      enlace(
                          '¿Qué informe necesito?',
                          Icons.help_outline,
                          () => _ayudaDocumento(
                              context, 'degiro', anioEjercicioActual)),
                    ],
                  ),
                  slot(
                    clave: 'plantilla',
                    titulo: 'Otro bróker (plantilla CSV)',
                    subtitulo:
                        'Para brókeres sin lector propio: tus compras y ventas en nuestra plantilla.',
                    icono: Icons.table_chart_outlined,
                    doc: docPlantilla,
                    elegir: elegirArchivoCsv,
                    fijar: (d) => docPlantilla = d,
                    enlaces: [
                      enlace('Descargar la plantilla', Icons.download,
                          () => descargarPlantillaFifo(context)),
                      enlace(
                          '¿Cómo se rellena?',
                          Icons.help_outline,
                          () => _ayudaDocumento(
                              context, 'plantilla', anioEjercicioActual)),
                    ],
                  ),
                  SizedBox(height: 4),
                  InkWell(
                    onTap: (hayDocs && !analizando) ? analizarTodo : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: (hayDocs && !analizando)
                            ? primaryColor
                            : Color(0xFF9CA3AF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (analizando)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          else
                            Icon(Icons.analytics_outlined,
                                size: 18, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                              analizando
                                  ? 'Analizando...'
                                  : 'Analizar documentos',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: borderColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o',
                            style:
                                TextStyle(fontSize: 13, color: textSecondary)),
                      ),
                      Expanded(child: Divider(color: borderColor)),
                    ],
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: analizando
                        ? null
                        : () async {
                            await saveAnswer(question.id, 'manual');
                            final avanzo = await goToNextQuestion();
                            if (avanzo) setState(() {});
                          },
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: primaryColor),
                    label: Text('Prefiero rellenarlo yo a mano',
                        style: TextStyle(fontSize: 13.5, color: primaryColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
              break;

            case 'info':
              controlWidget = Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: secondaryColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.clarification.isNotEmpty
                            ? question.clarification
                            : 'Información',
                        style: TextStyle(
                            fontSize: 14, color: textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
              break;

            default:
              controlWidget = Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Control "${question.controlType}" no reconocido.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              );
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
                horizontal: estrecho ? 10 : 24, vertical: estrecho ? 16 : 24),
            child: Container(
              width: 600,
              constraints: BoxConstraints(maxHeight: altoMaxDialogo),
              decoration: BoxDecoration(
                color: bgCream,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 8)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined,
                                  size: 20, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Módulo ${question.module}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                          InkWell(
                            onTap: () async {
                              final salir = await showDialog<bool>(
                                context: context,
                                builder: (dc) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    constraints: BoxConstraints(maxWidth: 360),
                                    padding: EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: bgCream,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('¿Salir del cuestionario?',
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor)),
                                        SizedBox(height: 6),
                                        Text(
                                            'Tu progreso se guarda. Podrás continuar más tarde desde donde lo dejaste.',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary)),
                                        SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () =>
                                                    Navigator.of(dc).pop(false),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 13),
                                                  side: BorderSide(
                                                      color: primaryColor),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                child: Text('Seguir',
                                                    style: TextStyle(
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () =>
                                                    Navigator.of(dc).pop(true),
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 13),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                child: Text('Salir',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              if (salir == true) {
                                Navigator.of(ctx, rootNavigator: true).pop();
                              }
                            },
                            child: Icon(Icons.close,
                                size: 22, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 2, color: accentGold),
                    if (activeModules.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            for (int i = 0; i < activeModules.length; i++) ...[
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: i <= currentModuleIdx
                                        ? primaryColor
                                        : borderColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              if (i < activeModules.length - 1)
                                SizedBox(width: 4),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(rel, rel, rel, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              tituloAlternativo.isNotEmpty
                                  ? tituloAlternativo
                                  : question.questionText,
                              style: TextStyle(
                                  fontSize: estrecho ? 18 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  height: 1.3)),
                          if ((aclaracionAlternativa.isNotEmpty ||
                                  question.clarification.isNotEmpty) &&
                              question.controlType != 'info') ...[
                            SizedBox(height: 8),
                            Text(
                                aclaracionAlternativa.isNotEmpty
                                    ? aclaracionAlternativa
                                    : question.clarification,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                    if (origenImportado.isNotEmpty &&
                        question.controlType != 'yesNo' &&
                        question.controlType != 'datosFiscalesUpload') ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(rel, 0, rel, 12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2E7D32).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Color(0xFF2E7D32)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_outlined,
                                  size: 18, color: Color(0xFF2E7D32)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Importado de tus documentos: '
                                  '$origenImportado. Revisa el importe y '
                                  'pulsa Confirmar; puedes corregirlo si '
                                  'no es correcto.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: textPrimary,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: rel),
                      child: controlWidget,
                    ),
                    if (question.shortHelp.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: rel),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(() => showHelp = !showHelp),
                              child: Row(
                                children: [
                                  Icon(Icons.help_outline,
                                      size: 16, color: primaryColor),
                                  SizedBox(width: 6),
                                  Text('¿Por qué se pregunta esto?',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600)),
                                  Icon(
                                      showHelp
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: primaryColor),
                                ],
                              ),
                            ),
                            if (showHelp) ...[
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Text(question.shortHelp,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.5)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: estrecho ? 20 : 28),
                    Padding(
                      padding: EdgeInsets.fromLTRB(rel, 0, rel, rel),
                      child: Row(
                        children: [
                          if (hasPrevious)
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await goToPreviousQuestion();
                                  selectedOption = null;
                                  multiSelected = {};
                                  selectedDate = null;
                                  textController.clear();
                                  showHelp = false;
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: primaryColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text('Atrás',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor)),
                                  ),
                                ),
                              ),
                            ),
                          if (hasPrevious) SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                String answerValue = '';
                                switch (question.controlType) {
                                  case 'yesNo':
                                  case 'singleSelect':
                                  case 'dropdown':
                                    answerValue = selectedOption ?? '';
                                    break;
                                  case 'multiSelect':
                                    answerValue = multiSelected.join(',');
                                    break;
                                  case 'date':
                                    answerValue = selectedDate == null
                                        ? ''
                                        : '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}';
                                    break;
                                  case 'amount':
                                    // Se guarda siempre como 75.891,42.
                                    final n =
                                        _leerNumeroEs(textController.text);
                                    answerValue = n == null
                                        ? textController.text
                                        : _numEs(n);
                                    break;
                                  case 'integer':
                                  case 'text':
                                    answerValue = textController.text;
                                    break;
                                }
// La pantalla de inmuebles no guarda un valor
                                // de texto; los inmuebles se guardan aparte.
                                if (question.controlType == 'inmuebles') {
                                  answerValue = 'ok';
                                }
                                // ← AQUÍ el bloque nuevo de validación
                                if (question.required &&
                                    answerValue.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Por favor, responde antes de continuar'),
                                      backgroundColor: Color(0xFFBA7517),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                await saveAnswer(question.id, answerValue);

                                // Si esta pregunta es una puerta de sí/no y
                                // se cierra, hay que borrar lo que colgaba de
                                // ella: si no, una cifra escrita antes se
                                // queda guardada y se sigue sumando en el
                                // cálculo aunque la pregunta ya no se vea.
                                if (question.controlType == 'yesNo') {
                                  for (final dependiente in visibles) {
                                    if (dependiente.conditionField ==
                                            question.id &&
                                        dependiente.conditionValue !=
                                            answerValue) {
                                      await clearAnswer(dependiente.id);
                                    }
                                  }
                                }

                                final advanced = await goToNextQuestion();
                                if (!advanced) {
                                  await finishInterview();

                                  // Cerrar el diálogo de la entrevista
                                  Navigator.of(ctx, rootNavigator: true).pop();

                                  // Mostrar diálogo de "calculando" con reloj girando
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (c) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        padding: EdgeInsets.all(28),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFAFAF8),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const _RelojDeArena(),
                                            SizedBox(height: 18),
                                            Text('Calculando tu declaración...',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xFF2C3E50),
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  // Llamar al cálculo
                                  final resultadoJson =
                                      await calcularDeclaracion();

                                  // Cerrar el diálogo de "calculando"
                                  Navigator.of(context, rootNavigator: true)
                                      .pop();

                                  // Mostrar el informe con el desglose
                                  await mostrarInforme(context, resultadoJson);
                                  return;
                                }
                                selectedOption = null;
                                multiSelected = {};
                                selectedDate = null;
                                textController.clear();
                                showHelp = false;
                                setState(() {});
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                      isLast
                                          ? 'Finalizar'
                                          : (origenImportado.isNotEmpty
                                              ? 'Confirmar'
                                              : 'Continuar'),
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
        },
      );
    },
  );

  textController.dispose();
}

InputDecoration _inputDecoration(String hint, Color border, Color focus) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: focus, width: 2),
    ),
  );
}

class _RelojDeArena extends StatefulWidget {
  const _RelojDeArena();

  @override
  State<_RelojDeArena> createState() => _RelojDeArenaState();
}

class _RelojDeArenaState extends State<_RelojDeArena>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child:
          const Icon(Icons.hourglass_top, size: 44, color: Color(0xFF1B3A6B)),
    );
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

// ============================================================
// Ayuda para conseguir cada documento
// ============================================================
const String _urlDatosFiscalesAeat =
    'https://sede.agenciatributaria.gob.es/Sede/irpf/tengo-que-presentar-declaracion/consultar-datos-fiscales.html';
const String _urlIbkr = 'https://www.interactivebrokers.com/sso/Login';
const String _urlDegiro = 'https://trader.degiro.nl/login/es';

Widget _paso(int n, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: _kAzul, shape: BoxShape.circle),
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    fontSize: 13.5, color: _kTexto, height: 1.4)),
          ),
        ],
      ),
    );

Future<void> _ayudaDocumento(
    BuildContext context, String clave, int anio) async {
  String titulo;
  List<String> pasos;
  String? aviso;
  String? textoBoton;
  Future<void> Function()? accion;

  switch (clave) {
    case 'aeat':
      titulo = 'Tus datos fiscales de $anio';
      pasos = [
        'Pulsa "Ir a la web de la AEAT" y entra en "Datos fiscales" del '
            'ejercicio $anio.',
        'Identifícate con Cl@ve, certificado o DNI electrónico, o con tu '
            'número de referencia.',
        'Con los datos en pantalla, guárdalos en PDF desde Chrome o Edge: '
            'Ctrl+P y, como destino, "Guardar como PDF".',
        'Vuelve aquí, pulsa "Elegir" en Datos fiscales de la AEAT y sube ese PDF.',
      ];
      aviso = 'No uses "Microsoft Print to PDF": guarda el texto como '
          'dibujos y la app no puede leerlo.';
      textoBoton = 'Ir a la web de la AEAT';
      accion = () => launchURL(_urlDatosFiscalesAeat);
      break;
    case 'ibkr':
      titulo = 'Extracto de Interactive Brokers';
      pasos = [
        'Entra en el Portal de IBKR desde el navegador.',
        'Menú → Performance & Reports → Statements.',
        'En "Activity", pulsa la flecha de ejecutar (Run).',
        'Periodo: "Annual", ejercicio $anio. Si abriste la cuenta durante '
            'el año, elige "Custom Date Range" desde la apertura hasta el '
            '31/12/$anio.',
        'Formato: CSV. En las opciones avanzadas, idioma: English.',
        'Descarga el archivo .csv y súbelo aquí.',
      ];
      aviso = 'Tiene que ser el Activity Statement completo, en CSV y en '
          'inglés: la app lee sus secciones (Trades, Dividends, Interest...) '
          'por su nombre en inglés. Si tenías acciones compradas antes de '
          'ese periodo, la app te pedirá su fecha y precio de compra.';
      textoBoton = 'Ir a Interactive Brokers';
      accion = () => launchURL(_urlIbkr);
      break;
    case 'degiro':
      titulo = 'Informe Anual de DEGIRO';
      pasos = [
        'Entra en DEGIRO (web o app).',
        'Ve a Buzón → Documentos.',
        'Descarga el "Informe anual $anio" en PDF.',
        'Súbelo aquí tal cual, sin imprimirlo ni convertirlo.',
      ];
      aviso = 'Es el informe anual con ganancias y pérdidas, dividendos y '
          'comisiones, no el "resumen de costes y gastos", que DEGIRO '
          'también publica.';
      textoBoton = 'Ir a DEGIRO';
      accion = () => launchURL(_urlDegiro);
      break;
    default:
      titulo = 'Plantilla para otro bróker';
      pasos = [
        'Descarga la plantilla y ábrela con Excel o Google Sheets.',
        'Rellena una fila por cada compra o venta: fecha (AAAA-MM-DD), tipo '
            '(compra o venta), ISIN del valor, cantidad, precio y comisión.',
        'Incluye también las compras de años anteriores de las acciones '
            'que vendiste en $anio: sin ellas no se puede calcular el coste.',
        'Guárdala como CSV y súbela aquí.',
      ];
      aviso = 'Si esas ventas ya aparecen en tus datos fiscales de la AEAT '
          '(bancos españoles), no hace falta la plantilla: la app te pedirá '
          'solo el coste de compra de cada una.';
      textoBoton = 'Descargar la plantilla';
      accion = () => descargarPlantillaFifo(context);
  }

  // Copias finales para usarlas dentro del diálogo.
  final String? avisoTexto = aviso;
  final Future<void> Function()? accionBoton = accion;
  final String textoAccion = textoBoton ?? 'Abrir';

  await showDialog(
    context: context,
    builder: (ctx) => _ventanaApp(
      titulo: titulo,
      icono: Icons.help_outline,
      ancho: 500,
      onCerrar: () => Navigator.pop(ctx),
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _tituloVentana('Cómo conseguirlo'),
          const SizedBox(height: 14),
          for (var i = 0; i < pasos.length; i++) _paso(i + 1, pasos[i]),
          if (avisoTexto != null) ...[
            const SizedBox(height: 4),
            _avisoCaja(avisoTexto),
          ],
        ],
      ),
      botones: [
        _botonSecundario('Cerrar', () => Navigator.pop(ctx)),
        if (accionBoton != null)
          _botonPrimario(textoAccion, () async {
            Navigator.pop(ctx);
            await accionBoton();
          }),
      ],
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
