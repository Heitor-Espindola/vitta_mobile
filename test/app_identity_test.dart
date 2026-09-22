import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher uses Vitta name and generated official icon', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="Vitta"'));
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, isNot(contains('android:label="vitta_mobile"')));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('image_path: assets/images/logoapp.jpg'));
    expect(File('assets/images/logoapp.jpg').existsSync(), isTrue);

    const expectedSizes = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in expectedSizes.entries) {
      final icon = File(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
      expect(
        icon.existsSync(),
        isTrue,
        reason: 'ícone ausente em ${entry.key}',
      );
      final bytes = icon.readAsBytesSync();
      expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(
        data.getUint32(16),
        entry.value,
        reason: 'largura em ${entry.key}',
      );
      expect(data.getUint32(20), entry.value, reason: 'altura em ${entry.key}');
    }
  });
}
