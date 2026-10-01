import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_expanded_image_view.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - haySesion] action in HomePage widget.
  bool? resultadoSesion;
  // State field(s) for Slider widget.
  double? sliderValue;
  // Stores action output result for [Custom Action - haySesion] action in Container widget.
  bool? tieneSesion;
  // Stores action output result for [Custom Action - mostrarAcceso] action in Container widget.
  bool? sesionTrasLogin;
  // Stores action output result for [Custom Action - haySesion] action in Stack widget.
  bool? tieneSesionExistente;
  // Stores action output result for [Custom Action - mostrarAcceso] action in Stack widget.
  bool? sesionTrasLoginExistente;
  // Stores action output result for [Custom Action - haySesion] action in Stack widget.
  bool? sesionInicial;
  // Stores action output result for [Custom Action - haySesion] action in Stack widget.
  bool? sesionTrasCerrar;
  // Stores action output result for [Custom Action - mostrarAcceso] action in Stack widget.
  bool? sesionTrasAcceso;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
