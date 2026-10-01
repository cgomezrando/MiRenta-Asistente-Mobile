// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChildStruct extends BaseStruct {
  ChildStruct({
    DateTime? birthDate,
    bool? livesWithTaxpayer,
    bool? hasDisability,
    int? disabilityDegree,
    bool? sharesMinimum,
  })  : _birthDate = birthDate,
        _livesWithTaxpayer = livesWithTaxpayer,
        _hasDisability = hasDisability,
        _disabilityDegree = disabilityDegree,
        _sharesMinimum = sharesMinimum;

  // "birthDate" field.
  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;
  set birthDate(DateTime? val) => _birthDate = val;

  bool hasBirthDate() => _birthDate != null;

  // "livesWithTaxpayer" field.
  bool? _livesWithTaxpayer;
  bool get livesWithTaxpayer => _livesWithTaxpayer ?? false;
  set livesWithTaxpayer(bool? val) => _livesWithTaxpayer = val;

  bool hasLivesWithTaxpayer() => _livesWithTaxpayer != null;

  // "hasDisability" field.
  bool? _hasDisability;
  bool get hasDisability => _hasDisability ?? false;
  set hasDisability(bool? val) => _hasDisability = val;

  bool hasHasDisability() => _hasDisability != null;

  // "disabilityDegree" field.
  int? _disabilityDegree;
  int get disabilityDegree => _disabilityDegree ?? 0;
  set disabilityDegree(int? val) => _disabilityDegree = val;

  void incrementDisabilityDegree(int amount) =>
      disabilityDegree = disabilityDegree + amount;

  bool hasDisabilityDegree() => _disabilityDegree != null;

  // "sharesMinimum" field.
  bool? _sharesMinimum;
  bool get sharesMinimum => _sharesMinimum ?? false;
  set sharesMinimum(bool? val) => _sharesMinimum = val;

  bool hasSharesMinimum() => _sharesMinimum != null;

  static ChildStruct fromMap(Map<String, dynamic> data) => ChildStruct(
        birthDate: data['birthDate'] as DateTime?,
        livesWithTaxpayer: data['livesWithTaxpayer'] as bool?,
        hasDisability: data['hasDisability'] as bool?,
        disabilityDegree: castToType<int>(data['disabilityDegree']),
        sharesMinimum: data['sharesMinimum'] as bool?,
      );

  static ChildStruct? maybeFromMap(dynamic data) =>
      data is Map ? ChildStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'birthDate': _birthDate,
        'livesWithTaxpayer': _livesWithTaxpayer,
        'hasDisability': _hasDisability,
        'disabilityDegree': _disabilityDegree,
        'sharesMinimum': _sharesMinimum,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'birthDate': serializeParam(
          _birthDate,
          ParamType.DateTime,
        ),
        'livesWithTaxpayer': serializeParam(
          _livesWithTaxpayer,
          ParamType.bool,
        ),
        'hasDisability': serializeParam(
          _hasDisability,
          ParamType.bool,
        ),
        'disabilityDegree': serializeParam(
          _disabilityDegree,
          ParamType.int,
        ),
        'sharesMinimum': serializeParam(
          _sharesMinimum,
          ParamType.bool,
        ),
      }.withoutNulls;

  static ChildStruct fromSerializableMap(Map<String, dynamic> data) =>
      ChildStruct(
        birthDate: deserializeParam(
          data['birthDate'],
          ParamType.DateTime,
          false,
        ),
        livesWithTaxpayer: deserializeParam(
          data['livesWithTaxpayer'],
          ParamType.bool,
          false,
        ),
        hasDisability: deserializeParam(
          data['hasDisability'],
          ParamType.bool,
          false,
        ),
        disabilityDegree: deserializeParam(
          data['disabilityDegree'],
          ParamType.int,
          false,
        ),
        sharesMinimum: deserializeParam(
          data['sharesMinimum'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'ChildStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ChildStruct &&
        birthDate == other.birthDate &&
        livesWithTaxpayer == other.livesWithTaxpayer &&
        hasDisability == other.hasDisability &&
        disabilityDegree == other.disabilityDegree &&
        sharesMinimum == other.sharesMinimum;
  }

  @override
  int get hashCode => const ListEquality().hash([
        birthDate,
        livesWithTaxpayer,
        hasDisability,
        disabilityDegree,
        sharesMinimum
      ]);
}

ChildStruct createChildStruct({
  DateTime? birthDate,
  bool? livesWithTaxpayer,
  bool? hasDisability,
  int? disabilityDegree,
  bool? sharesMinimum,
}) =>
    ChildStruct(
      birthDate: birthDate,
      livesWithTaxpayer: livesWithTaxpayer,
      hasDisability: hasDisability,
      disabilityDegree: disabilityDegree,
      sharesMinimum: sharesMinimum,
    );
