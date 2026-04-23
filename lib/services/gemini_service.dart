import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:skripsi_keuangan/keys/api_keys.dart';

class GeminiService {
  static Future<void> initialize() async {
    Gemini.init(apiKey: ApiKeys.geminiApiKey);
  }

  static Future<String> generateText(
    String prompt, {
    String context = "",
  }) async {
    int maxRetry = 3;

    for (int i = 0; i < maxRetry; i++) {
      try {
        // 🔥 batasi context
        if (context.length > 1500) {
          context = context.substring(0, 1500);
        }

        final response = await Gemini.instance.prompt(
          parts: [
            Part.text("""
$context

Pertanyaan:
$prompt

Jawab dengan bahasa sederhana tanpa simbol seperti # atau *.
"""),
          ],
        );

        if (response != null && response.output != null) {
          String text = response.output!;

          // bersihkan markdown
          text = text.replaceAll('#', '').replaceAll('*', '');

          return text.trim();
        }

        return "AI tidak memberikan respon.";
      } catch (e) {
        print("Gemini Error: $e");

        // 🔥 HANDLE 429
        if (e.toString().contains("429")) {
          // delay bertahap (2s, 4s, 6s)
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue; // retry
        }

        return "Gagal memproses AI.";
      }
    }

    return "Server AI sedang sibuk.\nCoba lagi beberapa saat.";
  }
}
