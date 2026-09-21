import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher uses Vitta name and generated official icon', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="Vitta"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, isNot(contains('android:label="vitta_mobile"')));

    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final icon = File(
        'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      );
      expect(icon.existsSync(), isTrue, reason: 'ícone ausente em $density');
      expect(icon.lengthSync(), greaterThan(3000));
      expect(icon.readAsBytesSync().take(8).toList(), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
    }
  });
}
