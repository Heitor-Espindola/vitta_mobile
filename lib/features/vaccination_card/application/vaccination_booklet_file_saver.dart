import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VaccinationBookletFileSaver {
  VaccinationBookletFileSaver._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.vitta_mobile/file_export',
  );

  static bool get isDirectDownloadSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<String> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!isDirectDownloadSupported) {
      throw UnsupportedError(
        'O salvamento direto está disponível somente no Android.',
      );
    }

    final savedPath = await _channel.invokeMethod<String>(
      'savePdfToDownloads',
      <String, Object>{'bytes': bytes, 'fileName': fileName},
    );
    if (savedPath == null || savedPath.trim().isEmpty) {
      throw PlatformException(
        code: 'empty_path',
        message: 'O Android não informou onde o PDF foi salvo.',
      );
    }
    return savedPath;
  }
}
