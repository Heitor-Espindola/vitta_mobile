import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/vaccination_card/application/vaccination_booklet_file_saver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.vitta_mobile/file_export');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('saves the PDF in the public Vitta download folder', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return 'Download/Vitta/caderneta-digital-vitta.pdf';
        });

    final path = await VaccinationBookletFileSaver.saveToDownloads(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
      fileName: 'caderneta-digital-vitta.pdf',
    );

    expect(path, 'Download/Vitta/caderneta-digital-vitta.pdf');
    expect(receivedCall?.method, 'savePdfToDownloads');
    expect(receivedCall?.arguments['fileName'], 'caderneta-digital-vitta.pdf');
    expect(
      receivedCall?.arguments['bytes'],
      Uint8List.fromList([37, 80, 68, 70]),
    );
  });
}
