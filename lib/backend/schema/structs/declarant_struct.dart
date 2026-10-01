// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DeclarantStruct extends BaseStruct {
  DeclarantStruct({
    String? taxId,
    String? fullName,
    DateTime? birthDate,
    int? ownDisabilityDegree,
    int? payerCount,
    double? unionFee,
    List<PayerStruct>? payer,
  })  : _taxId = taxId,
        _fullName = fullName,
        _birthDate = birthDate,
        _ownDisabilityDegree = ownDisabilityDegree,
        _payerCount = payerCount,
        _unionFee = unionFee,
        _payer = payer;

  // "taxId" field.
  String? _taxId;
  String get taxId => _taxId ?? '';
  set taxId(String? val) => _taxId = val;

  bool hasTaxId() => _taxId != null;

  // "fullName" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  set fullName(String? val) => _fullName = val;

  bool hasFullName() => _fullName != null;

  // "birthDate" field.
  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;
  set birthDate(DateTime? val) => _birthDate = val;

  bool hasBirthDate() => _birthDate != null;

  // "ownDisabilityDegree" field.
  int? _ownDisabilityDegree;
  int get ownDisabilityDegree => _ownDisabilityDegree ?? 0;
  set ownDisabilityDegree(int? val) => _ownDisabilityDegree = val;

  void incrementOwnDisabilityDegree(int amount) =>
      ownDisabilityDegree = ownDisabilityDegree + amount;

  bool hasOwnDisabilityDegree() => _ownDisabilityDegree != null;

  // "payerCount" field.
  int? _payerCount;
  int get payerCount => _payerCount ?? 0;
  set payerCount(int? val) => _payerCount = val;

  void incrementPayerCount(int amount) => payerCount = payerCount + amount;

  bool hasPayerCount() => _payerCount != null;

  // "unionFee" field.
  double? _unionFee;
  double get unionFee => _unionFee ?? 0.0;
  set unionFee(double? val) => _unionFee = val;

  void incrementUnionFee(double amount) => unionFee = unionFee + amount;

  bool hasUnionFee() => _unionFee != null;

  // "Payer" field.
  List<PayerStruct>? _payer;
  List<PayerStruct> get payer => _payer ?? const [];
  set payer(List<PayerStruct>? val) => _payer = val;

  void updatePayer(Function(List<PayerStruct>) updateFn) {
    updateFn(_payer ??= []);
  }

  bool hasPayer() => _payer != null;

  static DeclarantStruct fromMap(Map<String, dynamic> data) => DeclarantStruct(
        taxId: data['taxId'] as String?,
        fullName: data['fullName'] as String?,
        birthDate: data['birthDate'] as DateTime?,
        ownDisabilityDegree: castToType<int>(data['ownDisabilityDegree']),
        payerCount: castToType<int>(data['payerCount']),
        unionFee: castToType<double>(data['unionFee']),
        payer: getStructList(
          data['Payer'],
          PayerStruct.fromMap,
        ),
      );

  static DeclarantStruct? maybeFromMap(dynamic data) => data is Map
      ? DeclarantStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'taxId': _taxId,
        'fullName': _fullName,
        'birthDate': _birthDate,
        'ownDisabilityDegree': _ownDisabilityDegree,
        'payerCount': _payerCount,
        'unionFee': _unionFee,
        'Payer': _payer?.map((e) => e.toMap()).toList(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'taxId': serializeParam(
          _taxId,
          ParamType.String,
        ),
        'fullName': serializeParam(
          _fullName,
          ParamType.String,
        ),
        'birthDate': serializeParam(
          _birthDate,
          ParamType.DateTime,
        ),
        'ownDisabilityDegree': serializeParam(
          _ownDisabilityDegree,
          ParamType.int,
        ),
        'payerCount': serializeParam(
          _payerCount,
          ParamType.int,
        ),
        'unionFee': serializeParam(
          _unionFee,
          ParamType.double,
        ),
        'Payer': serializeParam(
          _payer,
          ParamType.DataStruct,
          isList: true,
        ),
      }.withoutNulls;

  static DeclarantStruct fromSerializableMap(Map<String, dynamic> data) =>
      DeclarantStruct(
        taxId: deserializeParam(
          data['taxId'],
          ParamType.String,
          false,
        ),
        fullName: deserializeParam(
          data['fullName'],
          ParamType.String,
          false,
        ),
        birthDate: deserializeParam(
          data['birthDate'],
          ParamType.DateTime,
          false,
        ),
        ownDisabilityDegree: deserializeParam(
          data['ownDisabilityDegree'],
          ParamType.int,
          false,
        ),
        payerCount: deserializeParam(
          data['payerCount'],
          ParamType.int,
          false,
        ),
        unionFee: deserializeParam(
          data['unionFee'],
          ParamType.double,
          false,
        ),
        payer: deserializeStructParam<PayerStruct>(
          data['Payer'],
          ParamType.DataStruct,
          true,
          structBuilder: PayerStruct.fromSerializableMap,
        ),
      );

  @override
  String toString() => 'DeclarantStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    const listEquality = ListEquality();
    return other is DeclarantStruct &&
        taxId == other.taxId &&
        fullName == other.fullName &&
        birthDate == other.birthDate &&
        ownDisabilityDegree == other.ownDisabilityDegree &&
        payerCount == other.payerCount &&
        unionFee == other.unionFee &&
        listEquality.equals(payer, other.payer);
  }

  @override
  int get hashCode => const ListEquality().hash([
        taxId,
        fullName,
        birthDate,
        ownDisabilityDegree,
        payerCount,
        unionFee,
        payer
      ]);
}

DeclarantStruct createDeclarantStruct({
  String? taxId,
  String? fullName,
  DateTime? birthDate,
  int? ownDisabilityDegree,
  int? payerCount,
  double? unionFee,
}) =>
    DeclarantStruct(
      taxId: taxId,
      fullName: fullName,
      birthDate: birthDate,
      ownDisabilityDegree: ownDisabilityDegree,
      payerCount: payerCount,
      unionFee: unionFee,
    );
