import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

/// Uma aplicação de vacina registrada no histórico de uma pessoa.
///
/// Os getters legados mantêm compatibilidade de leitura com documentos e
/// widgets anteriores à adoção do contrato `vaccination_records`.
class VaccinationRecord {
  const VaccinationRecord({
    required this.id,
    required this.vaccineName,
    this.patientId = '',
    this.patientUid = '',
    this.vaccineId,
    this.doseLabel = '',
    this.doseNumber,
    this.appliedAt,
    this.nextDoseAt,
    this.lot,
    this.manufacturer,
    this.facilityId,
    this.facilityName,
    this.professionalUid,
    this.notes,
    this.source,
    this.createdAt,
    this.updatedAt,
    String childId = '',
    String responsibleId = '',
    String personId = '',
    String dose = '',
    String status = '',
    DateTime? applicationDate,
    DateTime? nextDoseDate,
    String? healthProfessionalId,
    String? healthUnit,
    String? batchNumber,
    String? healthUnitId,
    String? professionalId,
    String? createdBy,
  }) : _legacyChildId = childId,
       _legacyResponsibleId = responsibleId,
       _legacyPersonId = personId,
       _legacyDose = dose,
       _legacyStatus = status,
       _legacyApplicationDate = applicationDate,
       _legacyNextDoseDate = nextDoseDate,
       _legacyHealthProfessionalId = healthProfessionalId,
       _legacyHealthUnit = healthUnit,
       _legacyBatchNumber = batchNumber,
       _legacyHealthUnitId = healthUnitId,
       _legacyProfessionalId = professionalId,
       _legacyCreatedBy = createdBy;

  final String id;
  final String patientId;
  final String patientUid;
  final String? vaccineId;
  final String vaccineName;
  final String doseLabel;
  final int? doseNumber;
  final DateTime? appliedAt;
  final DateTime? nextDoseAt;
  final String? lot;
  final String? manufacturer;
  final String? facilityId;
  final String? facilityName;
  final String? professionalUid;
  final String? notes;
  final String? source;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String _legacyChildId;
  final String _legacyResponsibleId;
  final String _legacyPersonId;
  final String _legacyDose;
  final String _legacyStatus;
  final DateTime? _legacyApplicationDate;
  final DateTime? _legacyNextDoseDate;
  final String? _legacyHealthProfessionalId;
  final String? _legacyHealthUnit;
  final String? _legacyBatchNumber;
  final String? _legacyHealthUnitId;
  final String? _legacyProfessionalId;
  final String? _legacyCreatedBy;

  factory VaccinationRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) => VaccinationRecord.fromMap({...?document.data(), 'id': document.id});

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    final legacyPatientUid = _string(map['personId']).isNotEmpty
        ? _string(map['personId'])
        : _string(map['childId']);
    return VaccinationRecord(
      id: _string(map['id']),
      patientId: _string(map['patientId']),
      patientUid: _string(map['patientUid']).isNotEmpty
          ? _string(map['patientUid'])
          : legacyPatientUid,
      vaccineId: _nullableString(map['vaccineId']),
      vaccineName: _string(map['vaccineName']),
      doseLabel: _string(map['doseLabel']).isNotEmpty
          ? _string(map['doseLabel'])
          : _string(map['dose']),
      doseNumber: _int(map['doseNumber']),
      appliedAt: dateTimeFromMap(map['appliedAt'] ?? map['applicationDate']),
      nextDoseAt: dateTimeFromMap(map['nextDoseAt'] ?? map['nextDoseDate']),
      lot: _nullableString(
        map['lot'] ?? map['batchNumber'] ?? map['lotNumber'],
      ),
      manufacturer: _nullableString(map['manufacturer']),
      facilityId: _nullableString(map['facilityId'] ?? map['healthUnitId']),
      facilityName: _nullableString(map['facilityName'] ?? map['healthUnit']),
      professionalUid: _nullableString(
        map['professionalUid'] ??
            map['professionalId'] ??
            map['healthProfessionalId'],
      ),
      notes: _nullableString(map['notes']),
      source: _nullableString(map['source']),
      createdAt: dateTimeFromMap(map['createdAt']),
      updatedAt: dateTimeFromMap(map['updatedAt']),
      childId: _string(map['childId']),
      responsibleId: _string(map['responsibleId']),
      personId: _string(map['personId']),
      dose: _string(map['dose']),
      status: _string(map['status']),
      applicationDate: dateTimeFromMap(map['applicationDate']),
      nextDoseDate: dateTimeFromMap(map['nextDoseDate']),
      healthProfessionalId: _nullableString(map['healthProfessionalId']),
      healthUnit: _nullableString(map['healthUnit']),
      batchNumber: _nullableString(map['batchNumber'] ?? map['lotNumber']),
      healthUnitId: _nullableString(map['healthUnitId']),
      professionalId: _nullableString(map['professionalId']),
      createdBy: _nullableString(map['createdBy']),
    );
  }

  /// Mapa do contrato oficial. Timestamps de servidor devem ser adicionados
  /// pelo cliente que cria o documento.
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientId': effectivePatientId,
      if (vaccineId != null) 'vaccineId': vaccineId,
      'vaccineName': vaccineName,
      'doseLabel': effectiveDoseLabel,
      if (doseNumber != null) 'doseNumber': doseNumber,
      if (effectiveAppliedAt != null) 'appliedAt': effectiveAppliedAt,
      if (effectiveNextDoseAt != null) 'nextDoseAt': effectiveNextDoseAt,
      if (effectiveLot != null) 'lot': effectiveLot,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (effectiveFacilityId != null) 'facilityId': effectiveFacilityId,
      if (effectiveFacilityName != null) 'facilityName': effectiveFacilityName,
      if (effectiveProfessionalUid != null)
        'professionalUid': effectiveProfessionalUid,
      if (notes != null) 'notes': notes,
      if (source != null) 'source': source,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toMap() => {'id': id, ...toFirestore()};

  String get effectivePatientId {
    if (patientId.isNotEmpty) return patientId;
    if (patientUid.isNotEmpty) return patientUid;
    if (_legacyPersonId.isNotEmpty) return _legacyPersonId;
    return _legacyChildId;
  }

  @Deprecated('Use effectivePatientId.')
  String get effectivePatientUid => effectivePatientId;

  String get effectiveDoseLabel =>
      doseLabel.isNotEmpty ? doseLabel : _legacyDose;
  DateTime? get effectiveAppliedAt => appliedAt ?? _legacyApplicationDate;
  DateTime? get effectiveNextDoseAt => nextDoseAt ?? _legacyNextDoseDate;
  String? get effectiveLot => lot ?? _legacyBatchNumber;
  String? get effectiveFacilityId => facilityId ?? _legacyHealthUnitId;
  String? get effectiveFacilityName => facilityName ?? _legacyHealthUnit;
  String? get effectiveProfessionalUid =>
      professionalUid ??
      _legacyProfessionalId ??
      _legacyHealthProfessionalId ??
      _legacyCreatedBy;

  // Aliases usados pelo código legado. Novos usos devem preferir o contrato.
  String get childId => effectivePatientId;
  String get responsibleId => _legacyResponsibleId;
  String get personId => effectivePatientId;
  String get dose => effectiveDoseLabel;
  String get status => _legacyStatus;
  DateTime? get applicationDate => effectiveAppliedAt;
  DateTime? get nextDoseDate => effectiveNextDoseAt;
  String? get healthProfessionalId => effectiveProfessionalUid;
  String? get healthUnit => effectiveFacilityName;
  String? get batchNumber => effectiveLot;
  String? get healthUnitId => effectiveFacilityId;
  String? get professionalId => effectiveProfessionalUid;
  String? get createdBy => _legacyCreatedBy;
}

String _string(Object? value) => value is String ? value.trim() : '';

String? _nullableString(Object? value) {
  final parsed = _string(value);
  return parsed.isEmpty ? null : parsed;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return value is String ? int.tryParse(value) : null;
}
