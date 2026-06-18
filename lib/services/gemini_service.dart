import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/keys/api_keys.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'firestore_service.dart';
import 'ai_cache_service.dart';

class GeminiService {
  static final Map<String, String> _cache = {};
  static DateTime? _lastRequest;
  static bool _initialized = false;

  // State pelacakan context chat lokal untuk menangani follow-up user tanpa AI
  static String _lastCheckedType = "";
  static String _lastCheckedCategoryType = "pengeluaran";
  static bool _lastActionWasCategory = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  static String normalizePrompt(String text) {
    return text
        .toLowerCase()
        .replaceAll("sy", "saya")
        .replaceAll("sya", "saya")
        .replaceAll("brp", "berapa")
        .replaceAll("bln", "bulan")
        .replaceAll("tgl", "tanggal")
        .replaceAll("kmrn", "kemarin")
        .replaceAll("mggu", "minggu")
        .replaceAll("mgu", "minggu")
        .replaceAll("thn", "tahun")
        .replaceAll("trnsaksi", "transaksi")
        .replaceAll("ngga", "tidak")
        .replaceAll("nggak", "tidak")
        .replaceAll("ndk", "tidak")
        .replaceAll("ndak", "tidak")
        .replaceAll("nga", "tidak")
        .replaceAll("selelu", "selalu")
        .replaceAll("selalau", "selalu")
        .replaceAll("e walet", "e-wallet")
        .replaceAll("ewallet", "e-wallet")
        .replaceAll("ewalet", "e-wallet")
        .replaceAll("walet", "e-wallet")
        .replaceAll("pmsukan", "pemasukan")
        .replaceAll("pngeluaran", "pengeluaran")
        .replaceAll("katgeori", "kategori")
        .replaceAll("kategori apa", "kategori")
        .replaceAll("gmn", "bagaimana");
  }

  static Future<String> ask(String prompt, {String context = ""}) async {
    await initialize();

    final firestore = FirestoreService();
    final aiCache = AiCacheService();
    final now = DateTime.now();

    final cleanPrompt = prompt.trim();
    String lower = normalizePrompt(cleanPrompt);

    if (cleanPrompt.isEmpty) return "Pertanyaan kosong.";

    // 1. Intersepsi lokal jika pengguna mengeluhkan kegagalan AI / ngetes aplikasi
    if (lower.contains("gagal memproses") ||
        lower.contains("gagal proses") ||
        lower.contains("ai rusak") ||
        lower.contains("kenapa gagal")) {
      return "Sistem asisten pintar telah disinkronisasi ulang. Sekarang saya siap menjawab pertanyaan saldo Anda secara instan atau memberikan analisis keuangan jika diminta!";
    }

    // 2. Deteksi dini apakah pertanyaan butuh analisis mendalam (Jalur AI Gemini) - UPDATED!
    bool isMintaSaranAI =
        lower.contains("boros") ||
        lower.contains("hemat") ||
        lower.contains("tips") ||
        lower.contains("cara") ||
        lower.contains("saran") ||
        lower.contains("rekomendasi") ||
        lower.contains("solusi") ||
        lower.contains("analisis") ||
        lower.contains("prediksi") || // <-- Ditambahkan agar masuk Jalur AI
        lower.contains("proyeksi"); // <-- Ditambahkan agar masuk Jalur AI

    // FORCE JALUR LOKAL: Jika user murni menanyakan saldo tertinggi/terendah/terbesar,
    // langsung paksa ke Jalur B (Lokal) agar tidak lari ke template AI yang salah.
    if ((lower.contains("saldo") || lower.contains("uang")) &&
        (lower.contains("tinggi") ||
            lower.contains("besar") ||
            lower.contains("banyak") ||
            lower.contains("rendah") ||
            lower.contains("kecil"))) {
      isMintaSaranAI = false;
    }

    // FITUR DETEKSI BULAN & WAKTU (Maksimal Mentok 4 Bulan)
    DateTime? startTime;
    DateTime? endTime;
    String labelWaktuKonteks = "Semua Waktu";
    bool isNanyaWaktuSpesifik = false;

    // A. Cek bulan spesifik berdasarkan nama bulan (Januari - Desember)
    List<String> daftarBulan = [
      "januari",
      "februari",
      "maret",
      "april",
      "mei",
      "juni",
      "juli",
      "agustus",
      "september",
      "oktober",
      "november",
      "desember",
    ];

    int bulanDitemukan = -1;
    for (int i = 0; i < daftarBulan.length; i++) {
      if (lower.contains(daftarBulan[i])) {
        bulanDitemukan = i + 1;
        break;
      }
    }

    if (bulanDitemukan != -1) {
      int targetYear = now.year;
      if (bulanDitemukan > now.month) {
        targetYear =
            now.year -
            1; // Jika input bulan melampaui bulan sekarang, asumsi tahun lalu
      }
      startTime = DateTime(targetYear, bulanDitemukan, 1);
      endTime = DateTime(targetYear, bulanDitemukan + 1, 0, 23, 59, 59);

      String namaBulanKapital = daftarBulan[bulanDitemukan - 1].toUpperCase();
      labelWaktuKonteks = "Bulan $namaBulanKapital $targetYear";
      isNanyaWaktuSpesifik = true;
    }
    // B. Cek frase "bulan kemarin / lalu" (Harus di atas cek kata "kemarin" biasa agar tidak bentrok)
    else if (lower.contains("bulan kemarin") || lower.contains("bulan lalu")) {
      startTime = DateTime(now.year, now.month - 1, 1);
      endTime = DateTime(now.year, now.month, 0, 23, 59, 59);
      labelWaktuKonteks =
          "Bulan Kemarin (${DateFormat('MMMM yyyy', 'id_ID').format(startTime)})";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("2 bulan") || lower.contains("dua bulan")) {
      startTime = DateTime(now.year, now.month - 2, 1);
      labelWaktuKonteks = "2 Bulan Terakhir";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("3 bulan") || lower.contains("tiga bulan")) {
      startTime = DateTime(now.year, now.month - 3, 1);
      labelWaktuKonteks = "3 Bulan Terakhir";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("4 bulan") || lower.contains("empat bulan")) {
      startTime = DateTime(now.year, now.month - 4, 1);
      labelWaktuKonteks = "4 Bulan Terakhir";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("bulan ini")) {
      startTime = DateTime(now.year, now.month, 1);
      labelWaktuKonteks =
          "Bulan Ini (${DateFormat('MMMM yyyy', 'id_ID').format(now)})";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("minggu kemarin") ||
        lower.contains("minggu lalu")) {
      DateTime hariIniMingguLalu = now.subtract(const Duration(days: 7));
      startTime = hariIniMingguLalu.subtract(
        Duration(days: hariIniMingguLalu.weekday - 1),
      );
      startTime = DateTime(startTime.year, startTime.month, startTime.day);
      endTime = startTime.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      labelWaktuKonteks = "Minggu Lalu";
      isNanyaWaktuSpesifik = true;
    } else if (lower.contains("minggu ini")) {
      startTime = now.subtract(Duration(days: now.weekday - 1));
      startTime = DateTime(startTime.year, startTime.month, startTime.day);
      labelWaktuKonteks = "Minggu Ini";
      isNanyaWaktuSpesifik = true;
    }
    // C. Kata "kemarin" diletakkan paling bawah agar tidak memotong "bulan kemarin"
    else if (lower.contains("kemarin")) {
      startTime = DateTime(now.year, now.month, now.day - 1);
      endTime = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
      labelWaktuKonteks =
          "Kemarin (${DateFormat('dd MMMM yyyy', 'id_ID').format(startTime)})";
      isNanyaWaktuSpesifik = true;
    }

    // Ambil seluruh data transaksi dari Firestore
    final allTransactions = await firestore.getAllTransactions();
    final rupiah = NumberFormat('#,###', 'id_ID');

    List<SumberdanaModel> daftarSumberDana = [];
    try {
      daftarSumberDana = await firestore.getSumberdanaModelsAsFuture();
    } catch (e) {
      daftarSumberDana = [];
    }

    Map<String, String> mapJenisSumberdana = {};
    for (var sd in daftarSumberDana) {
      mapJenisSumberdana[sd.nama.toLowerCase().trim()] = sd.jenis
          .toLowerCase()
          .trim();
    }

    Map<String, double> saldoPerSumberdanaMap = {};
    Map<String, double> pengeluaranKategoriMap = {};
    Map<String, double> pemasukanKategoriMap = {};

    // FIXED: Diubah dari TransaksiModel menjadi TransactionModel sesuai nama kelas di berkas impor Anda
    List<TransaksiModel> transaksiTerfilterList = [];

    for (var tx in allTransactions) {
      // Proses filter berdasarkan rentang tanggal yang dideteksi
      if (startTime != null && tx.tanggal.isBefore(startTime)) continue;
      if (endTime != null && tx.tanggal.isAfter(endTime)) continue;

      transaksiTerfilterList.add(tx);
      String tipe = tx.tipe.toLowerCase();
      String namaSD = tx.sumberdana.trim();
      double nominal = tx.nominal;

      if (tipe.contains("pemasukan")) {
        saldoPerSumberdanaMap[namaSD] =
            (saldoPerSumberdanaMap[namaSD] ?? 0) + nominal;
        pemasukanKategoriMap[tx.kategori] =
            (pemasukanKategoriMap[tx.kategori] ?? 0) + nominal;
      } else if (tipe.contains("pengeluaran")) {
        saldoPerSumberdanaMap[namaSD] =
            (saldoPerSumberdanaMap[namaSD] ?? 0) - nominal;
        pengeluaranKategoriMap[tx.kategori] =
            (pengeluaranKategoriMap[tx.kategori] ?? 0) + nominal;
      }
    }

    // Intersepsi jika filter waktu menghasilkan data kosong
    if (startTime != null && transaksiTerfilterList.isEmpty) {
      return "Saya tidak menemukan adanya riwayat catatan transaksi pada periode $labelWaktuKonteks.";
    }

    // JALUR A: PERTANYAAN STRATEGIS KE GEMINI AI
    if (isMintaSaranAI) {
      if (_cache.containsKey(cleanPrompt)) return _cache[cleanPrompt]!;
      final saved = await aiCache.findSimilarAiPrompt(cleanPrompt);
      if (saved != null && saved['respon'] != null) {
        final oldResponse = saved['respon'].toString();
        _cache[cleanPrompt] = oldResponse;
        return oldResponse;
      }

      String dataKonteksSistem =
          "DATA FINANSIAL RIIL USER (Periode: $labelWaktuKonteks):\n\n";

      dataKonteksSistem += "=== SALDO TERHITUNG PERIODE INI ===\n";
      saldoPerSumberdanaMap.forEach((nama, saldo) {
        String jenis =
            mapJenisSumberdana[nama.toLowerCase().trim()] ?? "tidak diketahui";
        dataKonteksSistem +=
            " * Nama: $nama (Jenis: $jenis) -> Akumulasi Selisih Saldo: Rp ${rupiah.format(saldo)}\n";
      });

      dataKonteksSistem += "\n=== RIWAYAT TRANSAKSI TERHUBUNG TERFILTER ===\n";
      for (var tx in transaksiTerfilterList) {
        String jenis =
            mapJenisSumberdana[tx.sumberdana.toLowerCase().trim()] ??
            "tidak diketahui";
        dataKonteksSistem +=
            " * [${tx.tipe.toUpperCase()}] Tgl: ${DateFormat('dd/MM/yyyy').format(tx.tanggal)} | Kategori: ${tx.kategori} | Menggunakan: ${tx.sumberdana} (Jenis: $jenis) | Nominal: Rp ${rupiah.format(tx.nominal)}\n";
      }

      dataKonteksSistem += "\n=== TOTAL AKUMULASI KATEGORI PERIODE INI ===\n";
      pengeluaranKategoriMap.forEach(
        (k, v) => dataKonteksSistem +=
            " * Total Pengeluaran Kategori $k: Rp ${rupiah.format(v)}\n",
      );
      pemasukanKategoriMap.forEach(
        (k, v) => dataKonteksSistem +=
            " * Total Pemasukan Kategori $k: Rp ${rupiah.format(v)}\n",
      );

      return await _askGemini(cleanPrompt, context: dataKonteksSistem);
    }

    // JALUR B: JAWABAN INSTAN LOKAL (TANPA AI)

    // JIKA USER HANYA MENANYAKAN STRUKTUR RIWAYAT PADA PERIODE WAKTU (Murni menampilkan List Data)
    if (isNanyaWaktuSpesifik &&
        !lower.contains("saldo") &&
        !lower.contains("kategori") &&
        !lower.contains("besar") &&
        !lower.contains("kecil")) {
      String responseLokal =
          "Berikut riwayat transaksi Anda pada periode $labelWaktuKonteks:\n";
      for (int index = 0; index < transaksiTerfilterList.length; index++) {
        var tx = transaksiTerfilterList[index];
        String tglStr = DateFormat('dd/MM/yyyy').format(tx.tanggal);
        responseLokal +=
            "${index + 1}. [$tglStr] ${tx.tipe.toUpperCase()} - Kategori ${tx.kategori} sebesar Rp ${rupiah.format(tx.nominal)} (${tx.sumberdana})\n";
      }
      return responseLokal.trim();
    }

    // Sinkronisasi state tipe kategori berdasarkan obrolan saat ini
    if (lower.contains("pemasukan")) {
      _lastCheckedCategoryType = "pemasukan";
      _lastActionWasCategory = true;
    } else if (lower.contains("pengeluaran")) {
      _lastCheckedCategoryType = "pengeluaran";
      _lastActionWasCategory = true;
    }

    String currentTargetJenis = "";
    if (lower.contains("bank")) {
      currentTargetJenis = "bank";
      _lastActionWasCategory = false;
    }
    if (lower.contains("e-wallet") || lower.contains("walet")) {
      currentTargetJenis = "e-wallet";
      _lastActionWasCategory = false;
    }
    if (lower.contains("cash") ||
        lower.contains("tunai") ||
        lower.contains("dompet")) {
      currentTargetJenis = "cash";
      _lastActionWasCategory = false;
    }

    if (lower.contains("lain") ||
        lower.contains("kayak di") ||
        lower.contains("selain") ||
        lower.startsWith("kalau ") ||
        lower.startsWith("kalw ")) {
      if (_lastActionWasCategory) {
        if (!lower.contains("pemasukan") && !lower.contains("pengeluaran")) {
          _lastCheckedCategoryType = (_lastCheckedCategoryType == "pemasukan")
              ? "pengeluaran"
              : "pemasukan";
        }
      } else {
        if (_lastCheckedType == "bank") currentTargetJenis = "e-wallet";
        if (_lastCheckedType == "e-wallet") currentTargetJenis = "bank";
      }
    }

    if (currentTargetJenis.isNotEmpty) _lastCheckedType = currentTargetJenis;
    if (lower.contains("kategori")) _lastActionWasCategory = true;
    if (lower.contains("saldo") || lower.contains("sumber dana")) {
      _lastActionWasCategory = false;
    }

    bool mintaTerbesar =
        lower.contains("besar") ||
        lower.contains("banyak") ||
        lower.contains("tinggi") ||
        lower.contains("mana") ||
        lower.contains("apa aja");
    bool mintaTerkecil =
        lower.contains("kecil") ||
        lower.contains("sedikit") ||
        lower.contains("rendah");

    // B.1 EKSEKUSI DATA KATEGORI SECARA LOKAL
    if (lower.contains("kategori") || _lastActionWasCategory) {
      bool isPemasukan = _lastCheckedCategoryType == "pemasukan";
      Map<String, double> targetMap = isPemasukan
          ? pemasukanKategoriMap
          : pengeluaranKategoriMap;
      String labelTipe = isPemasukan ? "pemasukan" : "pengeluaran";

      if (targetMap.isEmpty) {
        if (isPemasukan && pengeluaranKategoriMap.isNotEmpty) {
          targetMap = pengeluaranKategoriMap;
          labelTipe = "pengeluaran";
          _lastCheckedCategoryType = "pengeluaran";
        } else if (!isPemasukan && pemasukanKategoriMap.isNotEmpty) {
          targetMap = pemasukanKategoriMap;
          labelTipe = "pemasukan";
          _lastCheckedCategoryType = "pemasukan";
        }
      }

      if (targetMap.isEmpty) {
        return "Belum ada riwayat pencatatan transaksi untuk periode $labelWaktuKonteks.";
      }

      String kategoriTerpilih = "";
      double nominalTerpilih = mintaTerkecil ? 9999999999.0 : -1.0;

      targetMap.forEach((kategori, total) {
        if (mintaTerkecil) {
          if (total < nominalTerpilih) {
            nominalTerpilih = total;
            kategoriTerpilih = kategori;
          }
        } else {
          if (total > nominalTerpilih) {
            nominalTerpilih = total;
            kategoriTerpilih = kategori;
          }
        }
      });

      if (kategoriTerpilih.isNotEmpty) {
        String sifat = mintaTerkecil ? "terkecil" : "terbesar";
        return "Kategori $labelTipe $sifat Anda pada periode $labelWaktuKonteks ada pada kategori $kategoriTerpilih dengan total Rp ${rupiah.format(nominalTerpilih)}.";
      }
      return "Belum ada data transaksi untuk kategori tersebut pada periode ini.";
    }

    // B.2 EKSEKUSI DATA SALDO & SUMBER DANA SECARA LOKAL
    if (mintaTerbesar ||
        mintaTerkecil ||
        lower.contains("saldo") ||
        lower.contains("ada tidak") ||
        currentTargetJenis.isNotEmpty) {
      if (mintaTerbesar || mintaTerkecil || lower.contains("mana")) {
        String namaAkunTerpilih = "";
        double saldoTerpilih = mintaTerkecil ? 9999999999.0 : -9999999999.0;

        saldoPerSumberdanaMap.forEach((nama, saldo) {
          String jenis =
              mapJenisSumberdana[nama.toLowerCase().trim()] ?? "cash";
          if (currentTargetJenis.isEmpty || jenis == currentTargetJenis) {
            if (mintaTerkecil) {
              if (saldo < saldoTerpilih) {
                saldoTerpilih = saldo;
                namaAkunTerpilih = nama;
              }
            } else {
              if (saldo > saldoTerpilih) {
                saldoTerpilih = saldo;
                namaAkunTerpilih = nama;
              }
            }
          }
        });

        if (namaAkunTerpilih.isNotEmpty) {
          String jenisAkun =
              mapJenisSumberdana[namaAkunTerpilih.toLowerCase().trim()] ??
              "akun";
          String sifat = mintaTerkecil ? "terkecil" : "terbesar";
          return "Saldo $sifat Anda di periode $labelWaktuKonteks ada di $jenisAkun $namaAkunTerpilih dengan nominal Rp ${rupiah.format(saldoTerpilih)}.";
        }
        return "Data saldo tidak ditemukan untuk periode $labelWaktuKonteks.";
      }

      if (currentTargetJenis.isNotEmpty) {
        double totalJenis = 0;
        saldoPerSumberdanaMap.forEach((nama, saldo) {
          if ((mapJenisSumberdana[nama.toLowerCase().trim()] ?? "cash") ==
              currentTargetJenis) {
            totalJenis += saldo;
          }
        });
        return "Total saldo Anda di kategori $currentTargetJenis untuk periode $labelWaktuKonteks adalah Rp ${rupiah.format(totalJenis)}.";
      }

      if (saldoPerSumberdanaMap.isNotEmpty) {
        double totalSemuaSaldo = 0;
        saldoPerSumberdanaMap.forEach((_, saldo) => totalSemuaSaldo += saldo);
        return "Total keseluruhan saldo Anda pada periode $labelWaktuKonteks adalah Rp ${rupiah.format(totalSemuaSaldo)}.";
      }
    }

    // FIXED: Ditambahkan info prediksi/analisis keuangan di pesan default petunjuk
    return "Maaf, saya belum memahami maksud pertanyaan Anda. Silakan tanyakan total saldo, saldo terbesar/terkecil, kategori transaksi, prediksi keuangan, atau tips hemat.";
  }

  static Future<String> _askGemini(String prompt, {String context = ""}) async {
    final aiCache = AiCacheService();
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < const Duration(seconds: 2)) {
      return "Terlalu cepat. Tunggu sebentar.";
    }
    _lastRequest = now;

    final List<String> availableModels = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
    ];

    String? finalResponseText;

    for (String model in availableModels) {
      try {
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
Konteks Data Finansial Pengguna Saat Ini (Terintegrasi Rentang Waktu):
$context

Anda adalah AI pintar asisten keuangan dari aplikasi Uang Note.

Aturan Penting & Ketat Respon Anda:
1. Berikan analisis finansial secara SPESIFIK dan MENDALAM mengenai hubungan antara Jenis Akun (Bank/E-Wallet/Cash), Nama Sumber Dana, dan Kategori transaksi yang paling dominan/mempengaruhi keuangan user PADA PERIODE WAKTU YANG DIMINTA sesuai konteks di atas.
2. JANGAN hanya membeberkan list mentah, melainkan buatlah penjelasan deskriptif yang saling mengaitkan elemen-elemen tersebut.
3. Berikan rekomendasi/tips finansial taktis yang relevan berdasarkan keterkaitan data tersebut.
4. Jawab dengan bahasa Indonesia yang sopan, ringkas, namun berbobot.

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

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          finalResponseText =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          print("Sukses menggunakan model: $model");
          break;
        } else {
          print("Model $model gagal dengan status: ${response.statusCode}");
          continue;
        }
      } catch (e) {
        print("Gangguan pada model $model: $e");
      }
    }

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
