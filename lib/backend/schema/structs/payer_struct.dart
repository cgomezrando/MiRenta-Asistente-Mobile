// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PayerStruct extends BaseStruct {
  PayerStruct({
    String? name,
    double? grossIncome,
    double? withholdings,
    double? socialSecurity,
    double? inKindIncome,
  })  : _name = name,
        _grossIncome = grossIncome,
        _withholdings = withholdings,
        _socialSecurity = socialSecurity,
        _inKindIncome = inKindIncome;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "grossIncome" field.
  double? _grossIncome;
  double get grossIncome => _grossIncome ?? 0.0;
  set grossIncome(double? val) => _grossIncome = val;

  void incrementGrossIncome(double amount) =>
      grossIncome = grossIncome + amount;

  bool hasGrossIncome() => _grossIncome != null;

  // "withholdings" field.
  double? _withholdings;
  double get withholdings => _withholdings ?? 0.0;
  set withholdings(double? val) => _withholdings = val;

  void incrementWithholdings(double amount) =>
      withholdings = withholdings + amount;

  bool hasWithholdings() => _withholdings != null;

  // "socialSecurity" field.
  double? _socialSecurity;
  double get socialSecurity => _socialSecurity ?? 0.0;
  set socialSecurity(double? val) => _socialSecurity = val;

  void incrementSocialSecurity(double amount) =>
      socialSecurity = socialSecurity + amount;

  bool hasSocialSecurity() => _socialSecurity != null;

  // "inKindIncome" field.
  double? _inKindIncome;
  double get inKindIncome => _inKindIncome ?? 0.0;
  set inKindIncome(double? val) => _inKindIncome = val;

  void incrementInKindIncome(double amount) =>
      inKindIncome = inKindIncome + amount;

  bool hasInKindIncome() => _inKindIncome != null;

  static PayerStruct fromMap(Map<String, dynamic> data) => PayerStruct(
        name: data['name'] as String?,
        grossIncome: castToType<double>(data['grossIncome']),
        withholdings: castToType<double>(data['withholdings']),
        socialSecurity: castToType<double>(data['socialSecurity']),
        inKindIncome: castToType<double>(data['inKindIncome']),
      );

  static PayerStruct? maybeFromMap(dynamic data) =>
      data is Map ? PayerStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'grossIncome': _grossIncome,
        'withholdings': _withholdings,
        'socialSecurity': _socialSecurity,
        'inKindIncome': _inKindIncome,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'grossIncome': serializeParam(
          _grossIncome,
          ParamType.double,
        ),
        'withholdings': serializeParam(
          _withholdings,
          ParamType.double,
        ),
        'socialSecurity': serializeParam(
          _socialSecurity,
          ParamType.double,
        ),
        'inKindIncome': serializeParam(
          _inKindIncome,
          ParamType.double,
        ),
      }.withoutNulls;

  static PayerStruct fromSerializableMap(Map<String, dynamic> data) =>
      PayerStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        grossIncome: deserializeParam(
          data['grossIncome'],
          ParamType.double,
          false,
        ),
        withholdings: deserializeParam(
          data['withholdings'],
          ParamType.double,
          false,
        ),
        socialSecurity: deserializeParam(
          data['socialSecurity'],
          ParamType.double,
          false,
        ),
        inKindIncome: deserializeParam(
          data['inKindIncome'],
          ParamType.double,
          false,
        ),
      );

  @override
  String toString() => 'PayerStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is PayerStruct &&
        name == other.name &&
        grossIncome == other.grossIncome &&
        withholdings == other.withholdings &&
        socialSecurity == other.socialSecurity &&
        inKindIncome == other.inKindIncome;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([name, grossIncome, withholdings, socialSecurity, inKindIncome]);
}

PayerStruct createPayerStruct({
  String? name,
  double? grossIncome,
  double? withholdings,
  double? socialSecurity,
  double? inKindIncome,
}) =>
    PayerStruct(
      name: name,
      grossIncome: grossIncome,
      withholdings: withholdings,
      socialSecurity: socialSecurity,
      inKindIncome: inKindIncome,
    );
