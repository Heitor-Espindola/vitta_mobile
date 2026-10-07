import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/core/utils/health_age_groups.dart';

void main() {
  test('Ministry child range ends on the tenth birthday', () {
    final birthDate = DateTime(2016, 10, 6);

    expect(
      isMinistryOfHealthChild(birthDate, onDate: DateTime(2026, 10, 5)),
      isTrue,
    );
    expect(
      isMinistryOfHealthChild(birthDate, onDate: DateTime(2026, 10, 6)),
      isFalse,
    );
  });

  test('missing and future birth dates do not enable the child wallet', () {
    expect(
      isMinistryOfHealthChild(null, onDate: DateTime(2026, 10, 6)),
      isFalse,
    );
    expect(
      isMinistryOfHealthChild(
        DateTime(2026, 10, 7),
        onDate: DateTime(2026, 10, 6),
      ),
      isFalse,
    );
  });
}
