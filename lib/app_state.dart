import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  List<QuestionStruct> _fullScript = [];
  List<QuestionStruct> get fullScript => _fullScript;
  set fullScript(List<QuestionStruct> value) {
    _fullScript = value;
  }

  void addToFullScript(QuestionStruct value) {
    fullScript.add(value);
  }

  void removeFromFullScript(QuestionStruct value) {
    fullScript.remove(value);
  }

  void removeAtIndexFromFullScript(int index) {
    fullScript.removeAt(index);
  }

  void updateFullScriptAtIndex(
    int index,
    QuestionStruct Function(QuestionStruct) updateFn,
  ) {
    fullScript[index] = updateFn(_fullScript[index]);
  }

  void insertAtIndexInFullScript(int index, QuestionStruct value) {
    fullScript.insert(index, value);
  }

  List<String> _activeModules = [];
  List<String> get activeModules => _activeModules;
  set activeModules(List<String> value) {
    _activeModules = value;
  }

  void addToActiveModules(String value) {
    activeModules.add(value);
  }

  void removeFromActiveModules(String value) {
    activeModules.remove(value);
  }

  void removeAtIndexFromActiveModules(int index) {
    activeModules.removeAt(index);
  }

  void updateActiveModulesAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    activeModules[index] = updateFn(_activeModules[index]);
  }

  void insertAtIndexInActiveModules(int index, String value) {
    activeModules.insert(index, value);
  }

  List<QuestionStruct> _visibleQuestions = [];
  List<QuestionStruct> get visibleQuestions => _visibleQuestions;
  set visibleQuestions(List<QuestionStruct> value) {
    _visibleQuestions = value;
  }

  void addToVisibleQuestions(QuestionStruct value) {
    visibleQuestions.add(value);
  }

  void removeFromVisibleQuestions(QuestionStruct value) {
    visibleQuestions.remove(value);
  }

  void removeAtIndexFromVisibleQuestions(int index) {
    visibleQuestions.removeAt(index);
  }

  void updateVisibleQuestionsAtIndex(
    int index,
    QuestionStruct Function(QuestionStruct) updateFn,
  ) {
    visibleQuestions[index] = updateFn(_visibleQuestions[index]);
  }

  void insertAtIndexInVisibleQuestions(int index, QuestionStruct value) {
    visibleQuestions.insert(index, value);
  }

  String _currentQuestionId = '';
  String get currentQuestionId => _currentQuestionId;
  set currentQuestionId(String value) {
    _currentQuestionId = value;
  }

  String _activeDeclarant = '';
  String get activeDeclarant => _activeDeclarant;
  set activeDeclarant(String value) {
    _activeDeclarant = value;
  }

  List<String> _navigationHistory = [];
  List<String> get navigationHistory => _navigationHistory;
  set navigationHistory(List<String> value) {
    _navigationHistory = value;
  }

  void addToNavigationHistory(String value) {
    navigationHistory.add(value);
  }

  void removeFromNavigationHistory(String value) {
    navigationHistory.remove(value);
  }

  void removeAtIndexFromNavigationHistory(int index) {
    navigationHistory.removeAt(index);
  }

  void updateNavigationHistoryAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    navigationHistory[index] = updateFn(_navigationHistory[index]);
  }

  void insertAtIndexInNavigationHistory(int index, String value) {
    navigationHistory.insert(index, value);
  }

  String _currentModule = '';
  String get currentModule => _currentModule;
  set currentModule(String value) {
    _currentModule = value;
  }

  List<FamilyUnitStruct> _familyUnit = [];
  List<FamilyUnitStruct> get familyUnit => _familyUnit;
  set familyUnit(List<FamilyUnitStruct> value) {
    _familyUnit = value;
  }

  void addToFamilyUnit(FamilyUnitStruct value) {
    familyUnit.add(value);
  }

  void removeFromFamilyUnit(FamilyUnitStruct value) {
    familyUnit.remove(value);
  }

  void removeAtIndexFromFamilyUnit(int index) {
    familyUnit.removeAt(index);
  }

  void updateFamilyUnitAtIndex(
    int index,
    FamilyUnitStruct Function(FamilyUnitStruct) updateFn,
  ) {
    familyUnit[index] = updateFn(_familyUnit[index]);
  }

  void insertAtIndexInFamilyUnit(int index, FamilyUnitStruct value) {
    familyUnit.insert(index, value);
  }

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
  }

  String _validationError = '';
  String get validationError => _validationError;
  set validationError(String value) {
    _validationError = value;
  }

  bool _repeatModalOpen = false;
  bool get repeatModalOpen => _repeatModalOpen;
  set repeatModalOpen(bool value) {
    _repeatModalOpen = value;
  }

  bool _sesionActiva = false;
  bool get sesionActiva => _sesionActiva;
  set sesionActiva(bool value) {
    _sesionActiva = value;
  }
}
