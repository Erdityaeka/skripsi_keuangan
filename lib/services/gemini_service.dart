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
        // Batasi panjang context agar tidak overload
        if (context.length > 1000) {
          context = context.substring(0, 1000);
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

          // Bersihkan markdown
          text = text.replaceAll('#', '').replaceAll('*', '');

          return text.trim();
        }

        return "AI tidak memberikan respon.";
      } catch (e) {
        print("Gemini Error (attempt $i): $e");

        // HANDLE 429
        if (e.toString().contains("429")) {
          // Retry dengan delay bertahap
          await Future.delayed(Duration(seconds: 3 * (i + 1)));
          if (i == maxRetry - 1) {
            return "Permintaan terlalu sering. Tunggu beberapa detik sebelum mencoba lagi.";
          }
          continue;
        }

        // HANDLE 503/529
        if (e.toString().contains("503") || e.toString().contains("529")) {
          if (i == maxRetry - 1) {
            return "Server AI sedang oVERLOAD Permintaan. Silakan coba lagi beberapa menit kemudian.";
          }
          await Future.delayed(Duration(seconds: 3 * (i + 1)));
          continue;
        }

        // HANDLE koneksi / error lain
        return "Gagal memproses AI. Periksa koneksi internet Anda.";
      }
    }

    // Jika semua retry gagal
    return "Server AI sedang sibuk.\nCoba lagi beberapa saat.";
  }
}
