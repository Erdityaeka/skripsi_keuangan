import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>?> scanStruk(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(
      inputImage,
    );

    String detectedToko = "Toko Tidak Diketahui";
    double detectedNominal = 0;

    if (recognizedText.blocks.isEmpty) return null;

    // --- LOGIKA NAMA TOKO UNIVERSAL (TANPA BRAND) ---
    // 1. Urutkan blok dari posisi paling atas ke bawah
    List<TextBlock> sortedBlocks = recognizedText.blocks.toList();
    sortedBlocks.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (var block in sortedBlocks) {
      String line = block.lines.first.text.trim();

      // 2. Filter baris sampah:
      // - Abaikan baris yang mengandung alamat (JL, KEC, KEL, NO)
      // - Abaikan baris yang mengandung nomor telepon (HP, TELP, 08xx)
      // - Abaikan baris yang isinya cuma angka/simbol (Tanggal/Jam)
      bool isAddress = line.toUpperCase().contains(
        RegExp(r'JL\.|KEC\.|KEL\.|KAB\.|NPWP|HTTP|WWW'),
      );
      bool isContact = line.toUpperCase().contains(RegExp(r'HP|TELP|08\d+'));
      bool hasLetters = line.contains(RegExp(r'[a-zA-Z]'));

      if (hasLetters && !isAddress && !isContact && line.length > 3) {
        detectedToko = line;
        break; // Baris pertama yang lolos filter biasanya adalah Nama Toko Utama
      }
    }

    // --- LOGIKA NOMINAL (VERSI YANG KAMU BILANG SUDAH BETUL) ---
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
            text.contains("KEMBALI"))
          continue;

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
  }

  void dispose() => _textRecognizer.close();
}
