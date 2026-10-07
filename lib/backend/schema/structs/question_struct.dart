// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class QuestionStruct extends BaseStruct {
  QuestionStruct({
    String? id,
    String? module,
    String? questionText,
    String? clarification,
    String? shortHelp,
    String? icon,
    String? controlType,
    List<String>? options,
    String? savesTo,
    bool? required,
    double? min,
    double? max,
    String? conditionField,
    String? conditionValue,
    double? order,
  })  : _id = id,
        _module = module,
        _questionText = questionText,
        _clarification = clarification,
        _shortHelp = shortHelp,
        _icon = icon,
        _controlType = controlType,
        _options = options,
        _savesTo = savesTo,
        _required = required,
        _min = min,
        _max = max,
        _conditionField = conditionField,
        _conditionValue = conditionValue,
        _order = order;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "module" field.
  String? _module;
  String get module => _module ?? '';
  set module(String? val) => _module = val;

  bool hasModule() => _module != null;

  // "questionText" field.
  String? _questionText;
  String get questionText => _questionText ?? '';
  set questionText(String? val) => _questionText = val;

  bool hasQuestionText() => _questionText != null;

  // "clarification" field.
  String? _clarification;
  String get clarification => _clarification ?? '';
  set clarification(String? val) => _clarification = val;

  bool hasClarification() => _clarification != null;

  // "shortHelp" field.
  String? _shortHelp;
  String get shortHelp => _shortHelp ?? '';
  set shortHelp(String? val) => _shortHelp = val;

  bool hasShortHelp() => _shortHelp != null;

  // "icon" field.
  String? _icon;
  String get icon => _icon ?? '';
  set icon(String? val) => _icon = val;

  bool hasIcon() => _icon != null;

  // "controlType" field.
  String? _controlType;
  String get controlType => _controlType ?? '';
  set controlType(String? val) => _controlType = val;

  bool hasControlType() => _controlType != null;

  // "options" field.
  List<String>? _options;
  List<String> get options => _options ?? const [];
  set options(List<String>? val) => _options = val;

  void updateOptions(Function(List<String>) updateFn) {
    updateFn(_options ??= []);
  }

  bool hasOptions() => _options != null;

  // "savesTo" field.
  String? _savesTo;
  String get savesTo => _savesTo ?? '';
  set savesTo(String? val) => _savesTo = val;

  bool hasSavesTo() => _savesTo != null;

  // "required" field.
  bool? _required;
  bool get required => _required ?? false;
  set required(bool? val) => _required = val;

  bool hasRequired() => _required != null;

  // "min" field.
  double? _min;
  double get min => _min ?? 0.0;
  set min(double? val) => _min = val;

  void incrementMin(double amount) => min = min + amount;

  bool hasMin() => _min != null;

  // "max" field.
  double? _max;
  double get max => _max ?? 0.0;
  set max(double? val) => _max = val;

  void incrementMax(double amount) => max = max + amount;

  bool hasMax() => _max != null;

  // "conditionField" field.
  String? _conditionField;
  String get conditionField => _conditionField ?? '';
  set conditionField(String? val) => _conditionField = val;

  bool hasConditionField() => _conditionField != null;

  // "conditionValue" field.
  String? _conditionValue;
  String get conditionValue => _conditionValue ?? '';
  set conditionValue(String? val) => _conditionValue = val;

  bool hasConditionValue() => _conditionValue != null;

  // "order" field.
  double? _order;
  double get order => _order ?? 0.0;
  set order(double? val) => _order = val;

  void incrementOrder(double amount) => order = order + amount;

  bool hasOrder() => _order != null;

  static QuestionStruct fromMap(Map<String, dynamic> data) => QuestionStruct(
        id: data['id'] as String?,
        module: data['module'] as String?,
        questionText: data['questionText'] as String?,
        clarification: data['clarification'] as String?,
        shortHelp: data['shortHelp'] as String?,
        icon: data['icon'] as String?,
        controlType: data['controlType'] as String?,
        options: getDataList(data['options']),
        savesTo: data['savesTo'] as String?,
        required: data['required'] as bool?,
        min: castToType<double>(data['min']),
        max: castToType<double>(data['max']),
        conditionField: data['conditionField'] as String?,
        conditionValue: data['conditionValue'] as String?,
        order: castToType<double>(data['order']),
      );

  static QuestionStruct? maybeFromMap(dynamic data) =>
      data is Map ? QuestionStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'module': _module,
        'questionText': _questionText,
        'clarification': _clarification,
        'shortHelp': _shortHelp,
        'icon': _icon,
        'controlType': _controlType,
        'options': _options,
        'savesTo': _savesTo,
        'required': _required,
        'min': _min,
        'max': _max,
        'conditionField': _conditionField,
        'conditionValue': _conditionValue,
        'order': _order,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'module': serializeParam(
          _module,
          ParamType.String,
        ),
        'questionText': serializeParam(
          _questionText,
          ParamType.String,
        ),
        'clarification': serializeParam(
          _clarification,
          ParamType.String,
        ),
        'shortHelp': serializeParam(
          _shortHelp,
          ParamType.String,
        ),
        'icon': serializeParam(
          _icon,
          ParamType.String,
        ),
        'controlType': serializeParam(
          _controlType,
          ParamType.String,
        ),
        'options': serializeParam(
          _options,
          ParamType.String,
          isList: true,
        ),
        'savesTo': serializeParam(
          _savesTo,
          ParamType.String,
        ),
        'required': serializeParam(
          _required,
          ParamType.bool,
        ),
        'min': serializeParam(
          _min,
          ParamType.double,
        ),
        'max': serializeParam(
          _max,
          ParamType.double,
        ),
        'conditionField': serializeParam(
          _conditionField,
          ParamType.String,
        ),
        'conditionValue': serializeParam(
          _conditionValue,
          ParamType.String,
        ),
        'order': serializeParam(
          _order,
          ParamType.double,
        ),
      }.withoutNulls;

  static QuestionStruct fromSerializableMap(Map<String, dynamic> data) =>
      QuestionStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        module: deserializeParam(
          data['module'],
          ParamType.String,
          false,
        ),
        questionText: deserializeParam(
          data['questionText'],
          ParamType.String,
          false,
        ),
        clarification: deserializeParam(
          data['clarification'],
          ParamType.String,
          false,
        ),
        shortHelp: deserializeParam(
          data['shortHelp'],
          ParamType.String,
          false,
        ),
        icon: deserializeParam(
          data['icon'],
          ParamType.String,
          false,
        ),
        controlType: deserializeParam(
          data['controlType'],
          ParamType.String,
          false,
        ),
        options: deserializeParam<String>(
          data['options'],
          ParamType.String,
          true,
        ),
        savesTo: deserializeParam(
          data['savesTo'],
          ParamType.String,
          false,
        ),
        required: deserializeParam(
          data['required'],
          ParamType.bool,
          false,
        ),
        min: deserializeParam(
          data['min'],
          ParamType.double,
          false,
        ),
        max: deserializeParam(
          data['max'],
          ParamType.double,
          false,
        ),
        conditionField: deserializeParam(
          data['conditionField'],
          ParamType.String,
          false,
        ),
        conditionValue: deserializeParam(
          data['conditionValue'],
          ParamType.String,
          false,
        ),
        order: deserializeParam(
          data['order'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'QuestionStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is QuestionStruct &&
        id == other.id &&
        module == other.module &&
        questionText == other.questionText &&
        clarification == other.clarification &&
        shortHelp == other.shortHelp &&
        icon == other.icon &&
        controlType == other.controlType &&
        listEquality.equals(options, other.options) &&
        savesTo == other.savesTo &&
        required == other.required &&
        min == other.min &&
        max == other.max &&
        conditionField == other.conditionField &&
        conditionValue == other.conditionValue &&
        order == other.order;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        module,
        questionText,
        clarification,
        shortHelp,
        icon,
        controlType,
        const ListEquality().hash(options),
        savesTo,
        required,
        min,
        max,
        conditionField,
        conditionValue,
        order
      ]);
}

QuestionStruct createQuestionStruct({
  String? id,
  String? module,
  String? questionText,
  String? clarification,
  String? shortHelp,
  String? icon,
  String? controlType,
  String? savesTo,
  bool? required,
  double? min,
  double? max,
  String? conditionField,
  String? conditionValue,
  double? order,
}) =>
    QuestionStruct(
      id: id,
      module: module,
      questionText: questionText,
      clarification: clarification,
      shortHelp: shortHelp,
      icon: icon,
      controlType: controlType,
      savesTo: savesTo,
      required: required,
      min: min,
      max: max,
      conditionField: conditionField,
      conditionValue: conditionValue,
      order: order,
    );
