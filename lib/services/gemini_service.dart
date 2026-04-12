import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:skripsi_keuangan/keys/api_keys.dart';

class GeminiService {
  static Future<void> initialize() async {
    try {
      Gemini.init(apiKey: ApiKeys.geminiApiKey);
    } catch (e) {
      print("Gemini Init Error: $e");
    }
  }

  static Future<String> generateText(
    String prompt, {
    String context = "",
  }) async {
    try {
      // PAKAI .prompt() - Ini jalur resmi masa depan agar warning hilang total
      final response = await Gemini.instance.prompt(
        parts: [
          Part.text("KONTEKS KEUANGAN: $context"),
          Part.text(
            "INSTRUKSI: Jangan pakai bintang (*), jawab dengan teks polos.",
          ),
          Part.text("PERTANYAAN USER: $prompt"),
        ],
      );

      // Mengambil data lewat .output (jalur resmi terbaru)
      if (response != null && response.output != null) {
        return response.output!.replaceAll('*', '').trim();
      }

      return "Respon kosong.";
    } catch (e) {
      print("Gemini Error: $e");
      return 'Gagal memproses AI.';
    }
  }
}
