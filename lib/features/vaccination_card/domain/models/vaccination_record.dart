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
    this.applicationDate,
    this.nextDoseDate,
    this.healthProfessionalId,
    this.healthUnit,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String responsibleId;
  final String? vaccineId;
  final String vaccineName;
  final String dose;
  final String status;
  final DateTime? applicationDate;
  final DateTime? nextDoseDate;
  final String? healthProfessionalId;
  final String? healthUnit;
  final DateTime? createdAt;

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      id: map['id'] as String? ?? '',
      childId: map['childId'] as String? ?? '',
      responsibleId: map['responsibleId'] as String? ?? '',
      vaccineId: map['vaccineId'] as String?,
      vaccineName: map['vaccineName'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      status: map['status'] as String? ?? '',
      applicationDate: dateTimeFromMap(map['applicationDate']),
      nextDoseDate: dateTimeFromMap(map['nextDoseDate']),
      healthProfessionalId: map['healthProfessionalId'] as String?,
      healthUnit: map['healthUnit'] as String?,
      createdAt: dateTimeFromMap(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'responsibleId': responsibleId,
      'vaccineId': vaccineId,
      'vaccineName': vaccineName,
      'dose': dose,
      'status': status,
      'applicationDate': applicationDate,
      'nextDoseDate': nextDoseDate,
      'healthProfessionalId': healthProfessionalId,
      'healthUnit': healthUnit,
      'createdAt': createdAt,
    };
  }

  VaccinationRecord copyWith({
    String? id,
    String? childId,
    String? responsibleId,
    String? vaccineId,
    String? vaccineName,
    String? dose,
    String? status,
    DateTime? applicationDate,
    DateTime? nextDoseDate,
    String? healthProfessionalId,
    String? healthUnit,
    DateTime? createdAt,
  }) {
    return VaccinationRecord(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      responsibleId: responsibleId ?? this.responsibleId,
      vaccineId: vaccineId ?? this.vaccineId,
      vaccineName: vaccineName ?? this.vaccineName,
      dose: dose ?? this.dose,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      nextDoseDate: nextDoseDate ?? this.nextDoseDate,
      healthProfessionalId: healthProfessionalId ?? this.healthProfessionalId,
      healthUnit: healthUnit ?? this.healthUnit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
