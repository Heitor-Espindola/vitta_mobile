/// Age boundaries used by the Brazilian Ministry of Health vaccination
/// calendar.
///
/// A child is a person from birth until 9 years, 11 months and 29 days. The
/// adolescent range starts on the tenth birthday. A missing or future birth
/// date is never inferred as a child.
bool isMinistryOfHealthChild(DateTime? birthDate, {DateTime? onDate}) {
  if (birthDate == null) return false;

  final reference = _dateOnly(onDate ?? DateTime.now());
  final birth = _dateOnly(birthDate);
  if (birth.isAfter(reference)) return false;

  final tenthBirthday = DateTime(birth.year + 10, birth.month, birth.day);
  return reference.isBefore(tenthBirthday);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
