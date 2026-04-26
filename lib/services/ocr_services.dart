import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // OCR utama
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>?> scanStruk(File imageFile) async {
    try {
      // Konversi gambar ke OCR input
      final inputImage = InputImage.fromFile(imageFile);

      // Proses OCR
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String detectedToko = "Toko Tidak Diketahui";
      double detectedNominal = 0;

      // Jika tidak ada teks
      if (recognizedText.blocks.isEmpty) {
        return null;
      }

      // --- LOGIKA NAMA TOKO UNIVERSAL (TANPA BRAND) ---
      // Urutkan blok dari atas ke bawah
      List<TextBlock> sortedBlocks = recognizedText.blocks.toList();

      sortedBlocks.sort(
        (a, b) => a.boundingBox.top.compareTo(b.boundingBox.top),
      );

      for (var block in sortedBlocks) {
        // Hindari block kosong
        if (block.lines.isEmpty) {
          continue;
        }

        String line = block.lines.first.text.trim();

        // Filter baris sampah
        bool isAddress = line.toUpperCase().contains(
          RegExp(r'JL\.|KEC\.|KEL\.|KAB\.|NPWP|HTTP|WWW'),
        );

        bool isContact = line.toUpperCase().contains(RegExp(r'HP|TELP|08\d+'));

        bool hasLetters = line.contains(RegExp(r'[a-zA-Z]'));

        if (hasLetters && !isAddress && !isContact && line.length > 3) {
          detectedToko = line;
          break;
        }
      }

      // --- LOGIKA NOMINAL (VERSI ASLI) ---
      List<TextLine> allLines = [];

      for (TextBlock block in recognizedText.blocks) {
        allLines.addAll(block.lines);
      }

      for (var line in allLines) {
        String text = line.text.toUpperCase().replaceAll(' ', '');

        if (text.contains("TOTAL") ||
            text.contains("JUMLAH") ||
            text.contains("HARGAJUAL")) {
          if (text.contains("ITEM") ||
              text.contains("QTY") ||
              text.contains("KEMBALI")) {
            continue;
          }

          double keywordY = line.boundingBox.center.dy;

          for (var l in allLines) {
            double diffY = (l.boundingBox.center.dy - keywordY).abs();

            if (diffY < 25) {
              String digits = l.text.replaceAll(RegExp(r'[^0-9]'), '');

              if (digits.isNotEmpty) {
                double? val = double.tryParse(digits);

                if (val != null && val > 100 && val > detectedNominal) {
                  detectedNominal = val;
                }
              }
            }
          }
        }
      }

      return {'judul': detectedToko, 'nominal': detectedNominal};
    } catch (e) {
      // Hindari crash jika OCR gagal
      return null;
    }
  }

  // Tutup OCR agar aman
  void dispose() => _textRecognizer.close();
}
