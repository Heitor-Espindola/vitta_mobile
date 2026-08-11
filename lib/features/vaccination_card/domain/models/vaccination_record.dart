import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class VaccinationRecord {
  const VaccinationRecord({
    required this.id,
    required this.childId,
    required this.responsibleId,
    required this.vaccineName,
    required this.dose,
    required this.status,
    this.vaccineId,
    this.personId = '',
    this.applicationDate,
    this.nextDoseDate,
    this.healthProfessionalId,
    this.healthUnit,
    this.batchNumber,
    this.manufacturer,
    this.healthUnitId,
    this.professionalId,
    this.createdBy,
    this.source,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String responsibleId;
  final String? vaccineId;
  final String personId;
  final String vaccineName;
  final String dose;
  final String status;
  final DateTime? applicationDate;
  final DateTime? nextDoseDate;
  final String? healthProfessionalId;
  final String? healthUnit;
  final String? batchNumber;
  final String? manufacturer;
  final String? healthUnitId;
  final String? professionalId;
  final String? createdBy;
  final String? source;
  final String? notes;
  final DateTime? createdAt;

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'] as String? ?? '',
      childId: map['childId'] as String? ?? map['personId'] as String? ?? '',
      responsibleId: map['responsibleId'] as String? ?? '',
      vaccineId: map['vaccineId'] as String?,
      personId: map['personId'] as String? ?? map['childId'] as String? ?? '',
      vaccineName: map['vaccineName'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      status: map['status'] as String? ?? '',
      applicationDate: dateTimeFromMap(map['applicationDate']),
      nextDoseDate: dateTimeFromMap(map['nextDoseDate']),
      healthProfessionalId: map['healthProfessionalId'] as String?,
      healthUnit: map['healthUnit'] as String?,
      batchNumber: map['batchNumber'] as String? ?? map['lotNumber'] as String?,
      manufacturer: map['manufacturer'] as String?,
      healthUnitId: map['healthUnitId'] as String?,
      professionalId:
          map['professionalId'] as String? ??
          map['healthProfessionalId'] as String?,
      createdBy: map['createdBy'] as String?,
      source: map['source'] as String?,
      notes: map['notes'] as String?,
      createdAt: dateTimeFromMap(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'responsibleId': responsibleId,
      'vaccineId': vaccineId,
      'personId': personId.isEmpty ? childId : personId,
      'vaccineName': vaccineName,
      'dose': dose,
      'status': status,
      'applicationDate': applicationDate,
      'nextDoseDate': nextDoseDate,
      'healthProfessionalId': healthProfessionalId,
      'healthUnit': healthUnit,
      'batchNumber': batchNumber,
      'manufacturer': manufacturer,
      'healthUnitId': healthUnitId,
      'professionalId': professionalId ?? healthProfessionalId,
      'createdBy': createdBy,
      'source': source,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  VaccinationRecord copyWith({
    String? id,
    String? childId,
    String? responsibleId,
    String? vaccineId,
    String? personId,
    String? vaccineName,
    String? dose,
    String? status,
    DateTime? applicationDate,
    DateTime? nextDoseDate,
    String? healthProfessionalId,
    String? healthUnit,
    String? batchNumber,
    String? manufacturer,
    String? healthUnitId,
    String? professionalId,
    String? createdBy,
    String? source,
    String? notes,
    DateTime? createdAt,
  }) {
    return VaccinationRecord(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      responsibleId: responsibleId ?? this.responsibleId,
      vaccineId: vaccineId ?? this.vaccineId,
      personId: personId ?? this.personId,
      vaccineName: vaccineName ?? this.vaccineName,
      dose: dose ?? this.dose,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      nextDoseDate: nextDoseDate ?? this.nextDoseDate,
      healthProfessionalId: healthProfessionalId ?? this.healthProfessionalId,
      healthUnit: healthUnit ?? this.healthUnit,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      healthUnitId: healthUnitId ?? this.healthUnitId,
      professionalId: professionalId ?? this.professionalId,
      createdBy: createdBy ?? this.createdBy,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
