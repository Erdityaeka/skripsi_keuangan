import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/keys/api_keys.dart';
import 'firestore_service.dart';
import 'ai_cache_service.dart';

class GeminiService {
  //  CACHE RAM
  static final Map<String, String> _cache = {};

  // Mencegah spam request Gemini
  static DateTime? _lastRequest;

  // Status inisialisasi
  static bool _initialized = false;

  // Menyimpan konteks pertanyaan terakhir
  static String _lastContext = "";

  // Menyimpan hasil transaksi terakhir untuk follow-up
  static List<dynamic> _lastTransactions = [];

  //  INIT GEMINI
  static Future<void> initialize() async {
    if (_initialized) return;
    Gemini.init(apiKey: ApiKeys.geminiApiKey);
    _initialized = true;
  }

  //  NORMALISASI TYPO
  static String normalizePrompt(String text) {
    return text
        .toLowerCase()
        .replaceAll("sy", "saya")
        .replaceAll("sya", "saya")
        .replaceAll("brp", "berapa")
        .replaceAll("bln", "bulan")
        .replaceAll("tgl", "tanggal")
        .replaceAll("kmrn", "kemarin")
        .replaceAll("thn", "tahun")
        .replaceAll("trnsaksi", "transaksi")
        .replaceAll("ngga", "tidak")
        .replaceAll("nggak", "tidak");
  }

  //  FORMAT TRANSAKSI
  static String formatTransaction(dynamic tx) {
    final rupiah = NumberFormat('#,###', 'id_ID');

    return "- ${tx.judul}\n"
        "  Nominal : Rp ${rupiah.format(tx.nominal)}\n"
        "  Tanggal : ${DateFormat('dd/MM/yyyy', 'id_ID').format(tx.tanggal)}\n"
        "  Kategori: ${tx.kategori ?? '-'}\n"
        "  Bank    : ${tx.bank ?? '-'}\n"
        "  Tipe    : ${tx.tipe ?? '-'}\n";
  }

  //  CEK BULAN
  static final Map<String, int> bulanMap = {
    "januari": 1,
    "februari": 2,
    "maret": 3,
    "april": 4,
    "mei": 5,
    "juni": 6,
    "juli": 7,
    "agustus": 8,
    "september": 9,
    "oktober": 10,
    "november": 11,
    "desember": 12,
  };

  //  FUNGSI UTAMA
  static Future<String> ask(String prompt, {String context = ""}) async {
    await initialize();

    final firestore = FirestoreService();
    final aiCache = AiCacheService();
    final now = DateTime.now();

    final cleanPrompt = prompt.trim();
    String lower = normalizePrompt(cleanPrompt);

    if (cleanPrompt.isEmpty) {
      return "Pertanyaan kosong.";
    }

    //  FOLLOW-UP KONTEKS BULAN
    bool containsMonth = bulanMap.keys.any((bulan) => lower.contains(bulan));

    if (containsMonth &&
        !lower.contains("saldo") &&
        !lower.contains("transaksi")) {
      if (_lastContext == "saldo") {
        lower = "saldo $lower";
      } else if (_lastContext == "transaksi") {
        lower = "transaksi $lower";
      }
    }

    //  SALDO
    if (lower.contains("saldo")) {
      _lastContext = "saldo";

      // Saldo kemarin
      if (lower.contains("kemarin")) {
        final saldo = await firestore.getSaldoUntilDate(
          now.subtract(const Duration(days: 1)),
        );

        return "Saldo Anda kemarin adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
      }

      // Saldo bulan kemarin
      if (lower.contains("bulan kemarin")) {
        final lastMonth = DateTime(now.year, now.month - 1);

        final saldo = await firestore.getSaldoByMonth(
          lastMonth.month,
          lastMonth.year,
        );

        return "Saldo bulan ${DateFormat('MMMM yyyy', 'id_ID').format(lastMonth)} adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
      }

      // Saldo bulan spesifik
      for (final bulan in bulanMap.keys) {
        if (lower.contains(bulan)) {
          final saldo = await firestore.getSaldoByMonth(
            bulanMap[bulan]!,
            now.year,
          );

          return "Saldo bulan $bulan ${now.year} adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
        }
      }

      // Saldo tahun lalu
      if (lower.contains("tahun lalu")) {
        final all = await firestore.getAllTransactions();
        double pemasukan = 0;
        double pengeluaran = 0;

        for (var tx in all) {
          if (tx.tanggal.year == now.year - 1) {
            if (tx.tipe.toLowerCase().contains("pemasukan")) {
              pemasukan += tx.nominal;
            } else {
              pengeluaran += tx.nominal;
            }
          }
        }

        return "Saldo tahun ${now.year - 1} adalah Rp ${NumberFormat('#,###', 'id_ID').format(pemasukan - pengeluaran)}";
      }

      // Saldo sekarang
      final saldo = await firestore.getCurrentSaldo();
      return "Per tanggal ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}, saldo Anda adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
    }

    //  TRANSAKSI
    if (lower.contains("transaksi") ||
        lower.contains("riwayat") ||
        lower.contains("pengeluaran") ||
        lower.contains("pemasukan") ||
        lower.contains("tanggal") ||
        lower.contains("bulan") ||
        lower.contains("minggu lalu") ||
        lower.contains("tahun lalu")) {
      _lastContext = "transaksi";

      final all = await firestore.getAllTransactions();
      List<dynamic> hasil = [];

      // Minggu lalu
      if (lower.contains("minggu lalu")) {
        final start = now.subtract(Duration(days: now.weekday + 6));
        final end = start.add(const Duration(days: 6));

        hasil = all.where((tx) {
          return tx.tanggal.isAfter(start.subtract(const Duration(days: 1))) &&
              tx.tanggal.isBefore(end.add(const Duration(days: 1)));
        }).toList();
      }
      // Tahun lalu
      else if (lower.contains("tahun lalu")) {
        hasil = all.where((tx) {
          return tx.tanggal.year == now.year - 1;
        }).toList();
      }
      // Tanggal spesifik
      else if (RegExp(r'(\d{1,2})').hasMatch(lower)) {
        final day = int.parse(
          RegExp(r'(\d{1,2})').firstMatch(lower)!.group(1)!,
        );

        int month = now.month;
        int year = now.year;

        for (final bulan in bulanMap.keys) {
          if (lower.contains(bulan)) {
            month = bulanMap[bulan]!;
          }
        }

        hasil = all.where((tx) {
          return tx.tanggal.day == day &&
              tx.tanggal.month == month &&
              tx.tanggal.year == year;
        }).toList();
      }
      // Bulan kemarin
      else if (lower.contains("bulan kemarin")) {
        final lastMonth = DateTime(now.year, now.month - 1);

        hasil = all.where((tx) {
          return tx.tanggal.month == lastMonth.month &&
              tx.tanggal.year == lastMonth.year;
        }).toList();
      }
      // Bulan spesifik
      else {
        int month = now.month;
        int year = now.year;

        for (final bulan in bulanMap.keys) {
          if (lower.contains(bulan)) {
            month = bulanMap[bulan]!;
          }
        }

        hasil = all.where((tx) {
          return tx.tanggal.month == month && tx.tanggal.year == year;
        }).toList();
      }

      _lastTransactions = hasil;

      if (hasil.isEmpty) {
        return "Tidak ada transaksi ditemukan.";
      }

      String response = "Daftar transaksi:\n\n";

      for (var tx in hasil.take(10)) {
        response += "${formatTransaction(tx)}\n";
      }

      return response;
    }

    //  FOLLOW-UP APA AJA
    if (_lastContext == "transaksi" &&
        (lower == "apa aja" ||
            lower == "apa" ||
            lower.contains("selain itu"))) {
      if (_lastTransactions.isEmpty) {
        return "Tidak ada transaksi ditemukan.";
      }

      String response = "Daftar transaksi:\n\n";

      for (var tx in _lastTransactions.take(10)) {
        response += "${formatTransaction(tx)}\n";
      }

      return response;
    }

    //  CACHE RAM
    if (_cache.containsKey(cleanPrompt)) {
      return _cache[cleanPrompt]!;
    }

    //  CACHE FIRESTORE
    final saved = await aiCache.findSimilarAiPrompt(cleanPrompt);

    if (saved != null && saved['respon'] != null) {
      final oldResponse = saved['respon'].toString();

      _cache[cleanPrompt] = oldResponse;

      return oldResponse;
    }

    //  GEMINI ANALISIS
    return await _askGemini(cleanPrompt, context: context);
  }

  //  GEMINI ONLY
  static Future<String> _askGemini(String prompt, {String context = ""}) async {
    final aiCache = AiCacheService();
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < const Duration(seconds: 2)) {
      return "Terlalu cepat. Tunggu sebentar.";
    }

    _lastRequest = now;

    try {
      final response = await Gemini.instance.prompt(
        parts: [
          Part.text('''
$context

Anda adalah AI pintar aplikasi Uang Note.

Prioritas utama:
- keuangan pribadi
- tips hemat
- analendasi budgeting
- edukasi finansial

Jika pertanyaan pengguna di luar konteks keuangan, tetap jawab secara umum dengan informatif dan natural.

Untuk pertanyaan transaksi, saldo, tanggal, riwayat keuangan sederhana, serahkan pada sistem lokal dan jangan ambil alih.

Pertanyaan:
$prompt
Jawab maksimal 300 kata.
Gunakan poin-poin jika perlu.
'''),
        ],
      );

      if (response != null && response.output != null) {
        String text = response.output!
            .replaceAll('#', '')
            .replaceAll('*', '')
            .replaceAll('•', '-')
            .trim();

        if (text.isEmpty) {
          text = "AI tidak memberikan jawaban.";
        }

        _cache[prompt] = text;

        await aiCache.addAiResult(
          prompt,
          text,
          DateFormat('MMMM yyyy', 'id_ID').format(now),
        );

        return text;
      }
    } catch (e) {
      return "Gagal memproses AI.";
    }

    return "Server AI sedang sibuk.";
  }
}
