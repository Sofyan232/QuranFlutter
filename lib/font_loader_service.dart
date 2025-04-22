import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class FontLoaderService {
  static Future<void> loadFontFromUrl({
    required String fontUrl,
    required String fontFamily,
  }) async {
    try {
      final response = await http.get(Uri.parse(fontUrl));
      if (response.statusCode == 200) {
        final Uint8List fontData = response.bodyBytes;
        final ByteData byteData = ByteData.view(fontData.buffer);
        final FontLoader fontLoader = FontLoader(fontFamily)
          ..addFont(Future.value(byteData));
        await fontLoader.load();
        print('Font $fontFamily loaded successfully');
      } else {
        print('Failed to load font from URL, using fallback');
        // Rely on pubspec.yaml asset font as fallback
      }
    } catch (e) {
      print('Error loading font: $e, using fallback');
      // Rely on pubspec.yaml asset font as fallback
    }
  }
}