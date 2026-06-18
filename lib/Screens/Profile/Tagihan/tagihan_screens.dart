import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Profile/Tagihan/tambah_tagihan.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/tagihan_models.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class TagihanScreens extends StatefulWidget {
  const TagihanScreens({super.key});

  @override
  State<TagihanScreens> createState() => _TagihanScreensState();
}

class _TagihanScreensState extends State<TagihanScreens> {
  final firestore = FirestoreService();

  // Formatter untuk mengubah angka desimal menjadi teks rupiah reguler id
  final currencyFormatter = NumberFormat.simpleCurrency(
    locale: 'id',
    name: 'Rp ',
    decimalDigits: 0,
  );

  // Menyimpan list seluruh transaksi untuk kalkulasi saldo saat bayar tagihan
  List<TransaksiModel> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _listenToTransactions();
  }

  // Ambil data transaksi real-time
  void _listenToTransactions() {
    firestore.gettransaksi().listen((snapshot) {
      if (mounted) {
        setState(() {
          _allTransactions = snapshot;
        });
      }
    });
  }

  // Format Text Kapital
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Normalisasi Teks Sumber Dana
  String _normalize(String? val) {
    return (val ?? '').toLowerCase().trim();
  }

  String getStatus(TagihanModels tagihan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      tagihan.tanggalJatuhTempo.year,
      tagihan.tanggalJatuhTempo.month,
      tagihan.tanggalJatuhTempo.day,
    );

    if (dueDate.isBefore(today)) {
      return "TELAT";
    } else if (dueDate == today) {
      return "JATUH TEMPO";
    } else {
      return "AKAN DATANG";
    }
  }

  Color getStatusIconColor(String status) {
    switch (status) {
      case "TELAT":
        return rednotif;
      case "JATUH TEMPO":
        return yellownotif;
      default:
        return greennotif;
    }
  }

  // JENDELA POP-UP PERINGATAN SALDO MINUS
  void _showMinusAlert(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: rednotif, size: 28),
              const SizedBox(width: 10),
              Text("Saldo Tidak Cukup", style: hitamBold20),
            ],
          ),
          content: Text(pesan, style: teksdialogBold15),
          actions: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: merahHapus,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK", style: putihBold15),
              ),
            ),
          ],
        );
      },
    );
  }

  // BAYAR TAGIHAN (Dengan Validasi Cek Saldo Sumber Dana)
  Future<void> bayarTagihan(TagihanModels tagihan) async {
    final targetSumberdanaNormalized = _normalize(tagihan.sumberdana);

    // 1. Hitung sisa saldo berjalan di sumber dana yang bersangkutan
    final totalPemasukanSumberdana = _allTransactions
        .where(
          (tx) =>
              _normalize(tx.sumberdana) == targetSumberdanaNormalized &&
              tx.tipe.trim().toLowerCase() == "pemasukan",
        )
        .fold(0.0, (sum, tx) => sum + tx.nominal);

    final totalPengeluaranSumberdana = _allTransactions
        .where(
          (tx) =>
              _normalize(tx.sumberdana) == targetSumberdanaNormalized &&
              tx.tipe.trim().toLowerCase() == "pengeluaran",
        )
        .fold(0.0, (sum, tx) => sum + tx.nominal);

    final saldoSaatIni = totalPemasukanSumberdana - totalPengeluaranSumberdana;

    // Hitung estimasi sisa saldo setelah membayar nominal tagihan
    double sisaSimulasi = saldoSaatIni - tagihan.nominal;

    // 2. Proteksi ketat: jika saldo tidak mencukupi untuk membayar tagihan
    if (sisaSimulasi < 0) {
      // Format nominal minus menjadi bentuk teks "rp -5.000" secara dinamis
      final stringFormatRupiah = currencyFormatter
          .format(sisaSimulasi.abs())
          .replaceAll('Rp ', '');
      final formatTeksMinus = "Rp. -$stringFormatRupiah";

      _showMinusAlert(
        "Saldo anda akan minus di sumber dana '${tagihan.sumberdana.toUpperCase()}', $formatTeksMinus mohon input pemasukan terlebih dahulu sebelum membayar tagihan ini.",
      );
      return; // Stop eksekusi pembayaran!
    }

    // 3. Jalankan pembayaran jika saldo aman
    await firestore.executeTagihanPayment(tagihan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: greennotif,
          content: Center(
            child: Text(
              "${tagihan.judul} Berhasil Dibayar",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  // HAPUS TAGIHAN
  Future<void> hapusTagihan(TagihanModels tagihan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: putih,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Hapus Tagihan?", style: hitamBold20),
          content: Text(
            "Yakin ingin menghapus data tagihan '${tagihan.judul}'?",
            style: teksdialogBold15,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Batal", style: dialogBatalBold15),
            ),
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: merahHapus,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text("Hapus", style: putihBold15),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await firestore.deleteTagihan(tagihan.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: greennotif,
            content: Center(
              child: Text(
                "${tagihan.judul} berhasil dihapus",
                style: putihBold15,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hijauSimpan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahTagihan()),
          );
        },
        child: Icon(Icons.add, color: putih),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox.expand(child: _dataTagihan()),
      ),
    );
  }

  // APPBAR
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Tagihan', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // DATA TAGIHAN
  Widget _dataTagihan() {
    return StreamBuilder<List<TagihanModels>>(
      stream: firestore.getTagihan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tagihans = snapshot.data!;

        if (tagihans.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(
                      "Belum ada tagihan",
                      style: abuReguler15,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          );
        }

        // DATA LIST SORTING
        tagihans.sort((a, b) {
          String statusA = getStatus(a);
          String statusB = getStatus(b);

          int priorityA;
          int priorityB;

          switch (statusA) {
            case "TELAT":
              priorityA = 1;
              break;
            case "JATUH TEMPO":
              priorityA = 2;
              break;
            default:
              priorityA = 3;
          }

          switch (statusB) {
            case "TELAT":
              priorityB = 1;
              break;
            case "JATUH TEMPO":
              priorityB = 2;
              break;
            default:
              priorityB = 3;
          }

          final statusCompare = priorityA.compareTo(priorityB);
          if (statusCompare != 0) return statusCompare;

          return a.tanggalJatuhTempo.compareTo(b.tanggalJatuhTempo);
        });

        return ListView.builder(
          itemCount: tagihans.length,
          itemBuilder: (context, index) {
            return buildTagihanCard(tagihans[index]);
          },
        );
      },
    );
  }

  // CARD
  Widget buildTagihanCard(TagihanModels tagihan) {
    final status = getStatus(tagihan);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: putih,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardstroke, width: 2),
        boxShadow: [
          BoxShadow(
            color: hitam.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Tanggal: ${DateFormat('dd MMM yyyy').format(tagihan.tanggalJatuhTempo)}",
                    style: hitamReguler12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: getStatusIconColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),

          Divider(color: cardstroke, thickness: 1, height: 1),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: getStatusIconColor(status),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.receipt_long, color: putih, size: 22),
                  ),
                ),

                const SizedBox(width: 14),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalize(tagihan.judul),
                        style: hitamBold15,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        capitalize(tagihan.kategori),
                        style: hitamReguler12,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        capitalize(tagihan.sumberdana),
                        style: hitamReguler12,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Jam: ${DateFormat('HH:mm').format(tagihan.tanggalJatuhTempo)}",
                        style: hitamReguler12,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // NOMINAL
                Text(
                  "Rp.${NumberFormat('#,###', 'id_ID').format(tagihan.nominal).replaceAll(',', '.')}",
                  style: hitamBold15,
                ),
              ],
            ),
          ),

          // ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => bayarTagihan(tagihan),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: hijauSimpan,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text("Bayar Tagihan", style: putihBold15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => hapusTagihan(tagihan),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: merahHapus,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text("Hapus Tagihan", style: putihBold15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
