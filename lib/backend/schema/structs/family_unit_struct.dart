// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class FamilyUnitStruct extends BaseStruct {
  FamilyUnitStruct({
    int? year,
    String? autonomousCommunity,
    int? declarationType,
    List<DeclarantStruct>? declarantA,
    List<DeclarantStruct>? declarantB,
    List<ChildStruct>? children,
  })  : _year = year,
        _autonomousCommunity = autonomousCommunity,
        _declarationType = declarationType,
        _declarantA = declarantA,
        _declarantB = declarantB,
        _children = children;

  // "year" field.
  int? _year;
  int get year => _year ?? 0;
  set year(int? val) => _year = val;

  void incrementYear(int amount) => year = year + amount;

  bool hasYear() => _year != null;

  // "autonomousCommunity" field.
  String? _autonomousCommunity;
  String get autonomousCommunity => _autonomousCommunity ?? '';
  set autonomousCommunity(String? val) => _autonomousCommunity = val;

  bool hasAutonomousCommunity() => _autonomousCommunity != null;

  // "declarationType" field.
  int? _declarationType;
  int get declarationType => _declarationType ?? 0;
  set declarationType(int? val) => _declarationType = val;

  void incrementDeclarationType(int amount) =>
      declarationType = declarationType + amount;

  bool hasDeclarationType() => _declarationType != null;

  // "declarantA" field.
  List<DeclarantStruct>? _declarantA;
  List<DeclarantStruct> get declarantA => _declarantA ?? const [];
  set declarantA(List<DeclarantStruct>? val) => _declarantA = val;

  void updateDeclarantA(Function(List<DeclarantStruct>) updateFn) {
    updateFn(_declarantA ??= []);
  }

  bool hasDeclarantA() => _declarantA != null;

  // "declarantB" field.
  List<DeclarantStruct>? _declarantB;
  List<DeclarantStruct> get declarantB => _declarantB ?? const [];
  set declarantB(List<DeclarantStruct>? val) => _declarantB = val;

  void updateDeclarantB(Function(List<DeclarantStruct>) updateFn) {
    updateFn(_declarantB ??= []);
  }

  bool hasDeclarantB() => _declarantB != null;

  // "children" field.
  List<ChildStruct>? _children;
  List<ChildStruct> get children => _children ?? const [];
  set children(List<ChildStruct>? val) => _children = val;

  void updateChildren(Function(List<ChildStruct>) updateFn) {
    updateFn(_children ??= []);
  }

  bool hasChildren() => _children != null;

  static FamilyUnitStruct fromMap(Map<String, dynamic> data) =>
      FamilyUnitStruct(
        year: castToType<int>(data['year']),
        autonomousCommunity: data['autonomousCommunity'] as String?,
        declarationType: castToType<int>(data['declarationType']),
        declarantA: getStructList(
          data['declarantA'],
          DeclarantStruct.fromMap,
        ),
        declarantB: getStructList(
          data['declarantB'],
          DeclarantStruct.fromMap,
        ),
        children: getStructList(
          data['children'],
          ChildStruct.fromMap,
        ),
      );

  static FamilyUnitStruct? maybeFromMap(dynamic data) => data is Map
      ? FamilyUnitStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'year': _year,
        'autonomousCommunity': _autonomousCommunity,
        'declarationType': _declarationType,
        'declarantA': _declarantA?.map((e) => e.toMap()).toList(),
        'declarantB': _declarantB?.map((e) => e.toMap()).toList(),
        'children': _children?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'year': serializeParam(
          _year,
          ParamType.int,
        ),
        'autonomousCommunity': serializeParam(
          _autonomousCommunity,
          ParamType.String,
        ),
        'declarationType': serializeParam(
          _declarationType,
          ParamType.int,
        ),
        'declarantA': serializeParam(
          _declarantA,
          ParamType.DataStruct,
          isList: true,
        ),
        'declarantB': serializeParam(
          _declarantB,
          ParamType.DataStruct,
          isList: true,
        ),
        'children': serializeParam(
          _children,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static FamilyUnitStruct fromSerializableMap(Map<String, dynamic> data) =>
      FamilyUnitStruct(
        year: deserializeParam(
          data['year'],
          ParamType.int,
          false,
        ),
        autonomousCommunity: deserializeParam(
          data['autonomousCommunity'],
          ParamType.String,
          false,
        ),
        declarationType: deserializeParam(
          data['declarationType'],
          ParamType.int,
          false,
        ),
        declarantA: deserializeStructParam<DeclarantStruct>(
          data['declarantA'],
          ParamType.DataStruct,
          true,
          structBuilder: DeclarantStruct.fromSerializableMap,
        ),
        declarantB: deserializeStructParam<DeclarantStruct>(
          data['declarantB'],
          ParamType.DataStruct,
          true,
          structBuilder: DeclarantStruct.fromSerializableMap,
        ),
        children: deserializeStructParam<ChildStruct>(
          data['children'],
          ParamType.DataStruct,
          true,
          structBuilder: ChildStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'FamilyUnitStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is FamilyUnitStruct &&
        year == other.year &&
        autonomousCommunity == other.autonomousCommunity &&
        declarationType == other.declarationType &&
        listEquality.equals(declarantA, other.declarantA) &&
        listEquality.equals(declarantB, other.declarantB) &&
        listEquality.equals(children, other.children);
  }

  @override
  int get hashCode => const ListEquality().hash([
        year,
        autonomousCommunity,
        declarationType,
        declarantA,
        declarantB,
        children
      ]);
}

FamilyUnitStruct createFamilyUnitStruct({
  int? year,
  String? autonomousCommunity,
  int? declarationType,
}) =>
    FamilyUnitStruct(
      year: year,
      autonomousCommunity: autonomousCommunity,
      declarationType: declarationType,
    );
