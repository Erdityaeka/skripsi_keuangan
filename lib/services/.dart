import 'dart:convert'; // UTAMA: Untuk encoding & decoding JSON API
import 'package:http/http.dart' as http; // UTAMA: Untuk request HTTP murni
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/keys/api_keys.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'firestore_service.dart';
import 'ai_cache_service.dart';

class GeminiService {
  // CACHE RAM
  static final Map<String, String> _cache = {};

  // Mencegah spam request Gemini
  static DateTime? _lastRequest;

  // Menyimpan konteks pertanyaan terakhir
  static String _lastContext = "";

  // Menyimpan hasil transaksi terakhir untuk follow-up
  static List<TransaksiModel> _lastTransactions = [];

  // NORMALISASI TYPO
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

  // FORMAT TRANSAKSI
  static String formatTransaction(TransaksiModel tx) {
    final rupiah = NumberFormat('#,###', 'id_ID');

    return "- ${tx.judul}\n"
        "  Nominal : Rp ${rupiah.format(tx.nominal)}\n"
        "  Tanggal : ${DateFormat('dd/MM/yyyy', 'id_ID').format(tx.tanggal)}\n"
        "  Kategori: ${tx.kategori}\n"
        "  Sumber Dana: ${tx.sumberdana}\n"
        "  Tipe    : ${tx.tipe}\n";
  }

  // CEK BULAN
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

  // FUNGSI UTAMA (DIREMPED OLEH LOGIKA APLIKASI)
  static Future<String> ask(String prompt, {String context = ""}) async {
    final firestore = FirestoreService();
    final aiCache = AiCacheService();
    final now = DateTime.now();

    final cleanPrompt = prompt.trim();
    String lower = normalizePrompt(cleanPrompt);

    if (cleanPrompt.isEmpty) {
      return "Pertanyaan kosong.";
    }

    // =========================================================================
    // LOGIKA FILTER 1: AGREGASI DATA TERTINGGI / TERBANYAK
    // =========================================================================
    bool mintaDataTertinggi =
        lower.contains("tertinggi") ||
        lower.contains("paling banyak") ||
        lower.contains("terbesar") ||
        lower.contains("paling tinggi") ||
        lower.contains("banyak mengeluarkan") ||
        lower.contains("tinggi") ||
        lower.contains("terbanyak");

    if (mintaDataTertinggi) {
      final all = await firestore.getAllTransactions();
      final rupiah = NumberFormat('#,###', 'id_ID');

      List<SumberdanaModel> daftarBankData = [];
      try {
        daftarBankData = await firestore.getSumberdanaModelsAsFuture();
      } catch (e) {
        daftarBankData = [];
      }

      // Membuat Map bantuan lokalan untuk mencocokkan Nama Bank -> Jenis Akun
      Map<String, String> pencocokanjenisSumberdana = {};
      for (var b in daftarBankData) {
        pencocokanjenisSumberdana[b.nama.toLowerCase().trim()] = b.jenis;
      }

      // A. Deteksi Bank / Sumber Dana / Rekening
      if (lower.contains("bank") ||
          lower.contains("sumber dana") ||
          lower.contains("rekening")) {
        Map<String, double> sumberdanaGabunganMap = {};
        bool isPemasukan = lower.contains("pemasukan");
        bool isPengeluaran =
            lower.contains("pengeluaran") || lower.contains("mengeluarkan");

        for (var tx in all) {
          String sumberdanaName = tx.sumberdana;
          String tipeTx = tx.tipe.toLowerCase();

          // Ambil jenis asli dari database Bank berdasarkan nama bank di transaksi
          String jenisSumberdanaAsli =
              pencocokanjenisSumberdana[sumberdanaName.toLowerCase().trim()] ??
              "e-wallet";

          // Format key gabungan: "ShopeePay|e-wallet"
          String keyGabungan = "$sumberdanaName|$jenisSumberdanaAsli";

          if (isPemasukan && tipeTx.contains("pemasukan")) {
            sumberdanaGabunganMap[keyGabungan] =
                (sumberdanaGabunganMap[keyGabungan] ?? 0) + tx.nominal;
          } else if (isPengeluaran && tipeTx.contains("pengeluaran")) {
            sumberdanaGabunganMap[keyGabungan] =
                (sumberdanaGabunganMap[keyGabungan] ?? 0) + tx.nominal;
          } else if (!isPemasukan && !isPengeluaran) {
            // Umum -> Hitung total akumulasi pengeluaran
            if (tipeTx.contains("pengeluaran")) {
              sumberdanaGabunganMap[keyGabungan] =
                  (sumberdanaGabunganMap[keyGabungan] ?? 0) + tx.nominal;
            }
          }
        }

        String jenisInfo = isPemasukan ? "pemasukan" : "pengeluaran";
        String ringkasanSumberdana =
            "Data ringkasan total transaksi $jenisInfo per sumber dana saat ini:\n";

        sumberdanaGabunganMap.forEach((key, value) {
          var splitKey = key.split('|');
          String namaSumberdana = splitKey[0];
          String jenisSumberdana = splitKey[1];
          ringkasanSumberdana +=
              "- Sumber Dana $namaSumberdana dengan Jenis $jenisSumberdana: Rp ${rupiah.format(value)}\n";
        });

        return await _askGemini(cleanPrompt, context: ringkasanSumberdana);
      }

      // B. Deteksi Jenis Transaksi Saja
      if (lower.contains("jenis")) {
        Map<String, double> jenisMap = {};
        bool isPemasukan = lower.contains("pemasukan");

        for (var tx in all) {
          String sumberdanaName = tx.sumberdana;
          String tipeTx = tx.tipe.toLowerCase();

          // Cari jenis dari relasi koleksi sumber dana
          String jen =
              pencocokanjenisSumberdana[sumberdanaName.toLowerCase().trim()] ??
              "Lainnya";

          if (isPemasukan && tipeTx.contains("pemasukan")) {
            jenisMap[jen] = (jenisMap[jen] ?? 0) + tx.nominal;
          } else if (!isPemasukan && tipeTx.contains("pengeluaran")) {
            jenisMap[jen] = (jenisMap[jen] ?? 0) + tx.nominal;
          } else if (!isPemasukan) {
            if (tipeTx.contains("pengeluaran")) {
              jenisMap[jen] = (jenisMap[jen] ?? 0) + tx.nominal;
            }
          }
        }

        String ringkasanJenis = lower.contains("pemasukan")
            ? "Data ringkasan total pemasukan berdasarkan jenis transaksi saat ini:\n"
            : "Data ringkasan total pengeluaran berdasarkan jenis transaksi saat ini:\n";

        jenisMap.forEach((key, value) {
          ringkasanJenis += "- Jenis $key: Rp ${rupiah.format(value)}\n";
        });

        return await _askGemini(cleanPrompt, context: ringkasanJenis);
      }

      // C. Deteksi Kategori
      if (lower.contains("kategori")) {
        Map<String, double> kategoriMap = {};
        bool isPemasukan = lower.contains("pemasukan");

        for (var tx in all) {
          String tipeTx = tx.tipe.toLowerCase();
          if (isPemasukan && tx.tipe.toLowerCase().contains("pemasukan")) {
            String kat = tx.kategori;
            kategoriMap[kat] = (kategoriMap[kat] ?? 0) + tx.nominal;
          } else if (!isPemasukan && tipeTx.contains("pengeluaran")) {
            String kat = tx.kategori;
            kategoriMap[kat] = (kategoriMap[kat] ?? 0) + tx.nominal;
          }
        }

        String jenisInfo = isPemasukan ? "pemasukan" : "pengeluaran";
        String ringkasanKategori =
            "Data ringkasan total $jenisInfo per kategori saat ini:\n";
        kategoriMap.forEach((key, value) {
          ringkasanKategori += "- Kategori $key: Rp ${rupiah.format(value)}\n";
        });

        return await _askGemini(cleanPrompt, context: ringkasanKategori);
      }

      // D. Fallback Pemasukan Terbanyak Secara Umum
      if (lower.contains("pemasukan")) {
        Map<String, double> pemasukanMap = {};
        for (var tx in all) {
          if (tx.tipe.toLowerCase().contains("pemasukan")) {
            String kat = tx.kategori;
            pemasukanMap[kat] = (pemasukanMap[kat] ?? 0) + tx.nominal;
          }
        }
        String ringkasanPem = "Data ringkasan total pemasukan per kategori:\n";
        pemasukanMap.forEach((key, value) {
          ringkasanPem += "- Kategori $key: Rp ${rupiah.format(value)}\n";
        });
        return await _askGemini(cleanPrompt, context: ringkasanPem);
      }
    }

    // =========================================================================
    // LOGIKA FILTER 2: MANAJEMEN KONTEKS & RIWAYAT NORMAL
    // =========================================================================

    // FOLLOW-UP KONTEKS BULAN
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

    // SALDO
    if (lower.contains("saldo")) {
      _lastContext = "saldo";

      if (lower.contains("kemarin")) {
        final saldo = await firestore.getSaldoUntilDate(
          now.subtract(const Duration(days: 1)),
        );
        return "Saldo Anda kemarin adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
      }

      if (lower.contains("bulan kemarin")) {
        final lastMonth = DateTime(now.year, now.month - 1);
        final saldo = await firestore.getSaldoByMonth(
          lastMonth.month,
          lastMonth.year,
        );
        return "Saldo bulan ${DateFormat('MMMM yyyy', 'id_ID').format(lastMonth)} adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
      }

      for (final bulan in bulanMap.keys) {
        if (lower.contains(bulan)) {
          final saldo = await firestore.getSaldoByMonth(
            bulanMap[bulan]!,
            now.year,
          );
          return "Saldo bulan $bulan ${now.year} adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
        }
      }

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

      final saldo = await firestore.getCurrentSaldo();
      return "Per tanggal ${DateFormat('dd MMMM yyyy', 'id_ID').format(now)}, saldo Anda adalah Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}";
    }

    // TRANSAKSI LIST NORMAL
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
      List<TransaksiModel> hasil = [];

      if (lower.contains("minggu lalu")) {
        final start = now.subtract(Duration(days: now.weekday + 6));
        final end = start.add(const Duration(days: 6));

        hasil = all.where((tx) {
          return tx.tanggal.isAfter(start.subtract(const Duration(days: 1))) &&
              tx.tanggal.isBefore(end.add(const Duration(days: 1)));
        }).toList();
      } else if (lower.contains("tahun lalu")) {
        hasil = all.where((tx) {
          return tx.tanggal.year == now.year - 1;
        }).toList();
      } else if (RegExp(r'(\d{1,2})').hasMatch(lower)) {
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
      } else if (lower.contains("bulan kemarin")) {
        final lastMonth = DateTime(now.year, now.month - 1);

        hasil = all.where((tx) {
          return tx.tanggal.month == lastMonth.month &&
              tx.tanggal.year == lastMonth.year;
        }).toList();
      } else {
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

    // FOLLOW-UP APA AJA
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

    // CACHE RAM
    if (_cache.containsKey(cleanPrompt)) {
      return _cache[cleanPrompt]!;
    }

    // CACHE FIRESTORE
    final saved = await aiCache.findSimilarAiPrompt(cleanPrompt);

    if (saved != null && saved['respon'] != null) {
      final oldResponse = saved['respon'].toString();
      _cache[cleanPrompt] = oldResponse;
      return oldResponse;
    }

    // GEMINI ANALISIS UMUM
    return await _askGemini(cleanPrompt, context: context);
  }

  // GEMINI ENGINE DENGAN DIRECT HTTP POST & AUTO-FALLBACK MODEL YANG VALID
  // ... (Bagian atas kode tetap sama)

  static Future<String> _askGemini(String prompt, {String context = ""}) async {
    final aiCache = AiCacheService();
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < const Duration(seconds: 2)) {
      return "Terlalu cepat. Tunggu sebentar.";
    }
    _lastRequest = now;

    // HANYA gunakaan model yang terbukti stabil dan memiliki rute v1 yang valid
    final List<String> availableModels = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
    ];

    String? finalResponseText;
    int lastStatusCode = 200;

    for (String model in availableModels) {
      try {
        // URL dibuat dinamis berdasarkan model yang valid
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=${ApiKeys.geminiApiKey}',
        );

        final bodyRequestBody = {
          "contents": [
            {
              "parts": [
                {
                  "text":
                      '''
Konteks Data Finansial Pengguna Saat Ini:
$context

Anda adalah AI pintar asisten keuangan dari aplikasi Uang Note.

Aturan Penting & Ketat Respon Anda:
1. Jika disediakan data akumulasi Sumber Dana, analisis dan sebutkan entitas dengan nilai tertinggi/terbanyak, jenisnya, dan total nominalnya.
2. JANGAN menuliskan daftar transaksi mentah. Berikan jawaban dalam bentuk satu kesimpulan atau paragraf ringkas.
3. Berikan maksimal 1 tips finansial singkat.
4. Jika di luar konteks keuangan, jawab dengan sopan.

Pertanyaan Pengguna:
$prompt
''',
                },
              ],
            },
          ],
        };

        print("Mencoba request ke model: $model");

        final response = await http
            .post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(bodyRequestBody),
            )
            .timeout(const Duration(seconds: 15));

        lastStatusCode = response.statusCode;

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          finalResponseText =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];

          print("Sukses menggunakan model: $model");
          break; // Keluar dari loop jika berhasil
        } else {
          print("Model $model gagal dengan status: ${response.statusCode}");
          // Lanjut ke model berikutnya jika 404 atau 503
          continue;
        }
      } catch (e) {
        print("Gangguan pada model $model: $e");
      }
    }

    // Penanganan akhir jika semua model gagal
    if (finalResponseText == null) {
      return "Mohon maaf, server AI sedang sibuk. Silakan coba beberapa saat lagi.";
    }

    String text = finalResponseText
        .replaceAll('#', '')
        .replaceAll('*', '')
        .trim();
    _cache[prompt] = text;

    await aiCache.addAiResult(
      prompt,
      text,
      DateFormat('MMMM yyyy', 'id_ID').format(now),
    );

    return text;
  }
}
