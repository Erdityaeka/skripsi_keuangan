import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction_model.dart';

class PdfService {
  static Future<String> generateReport(
    List<TransaksiModel> transactions,
    DateTime startDate,
    DateTime endDate,
    String judulLaporan,
  ) async {
    // Membuat dokumen PDF baru
    final pdf = pw.Document();

    // Format mata uang Rupiah
    final currency = NumberFormat.simpleCurrency(
      locale: 'id',
      decimalDigits: 0,
    );

    // Variabel total
    double pemasukan = 0;
    double pengeluaran = 0;

    // Hitung total pemasukan & pengeluaran
    for (var tx in transactions) {
      if (tx.tipe == "pemasukan") {
        pemasukan += tx.nominal;
      } else {
        pengeluaran += tx.nominal;
      }
    }

    // Hitung saldo akhir
    final saldo = pemasukan - pengeluaran;

    // Tambahkan halaman PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Judul laporan
          pw.Center(
            child: pw.Text(
              judulLaporan,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 10),
          pw.Divider(),

          // Periode laporan
          pw.Text(
            "Periode : ${DateFormat('dd MMM yyyy', 'id').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id').format(endDate)}",
          ),

          pw.SizedBox(height: 10),

          // Ringkasan keuangan
          pw.Text("Pemasukan : ${currency.format(pemasukan)}"),
          pw.SizedBox(height: 10),
          pw.Text("Pengeluaran : ${currency.format(pengeluaran)}"),
          pw.SizedBox(height: 10),

          pw.Text(
            "Saldo : ${currency.format(saldo)}",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          // Tabel transaksi
          // ignore: deprecated_member_use
          pw.Table.fromTextArray(
            headers: [
              "No",
              "Tanggal",
              "Keterangan",
              "Pemasukan",
              "Pengeluaran",
              "Bank",
              "Kategori",
            ],

            data: List.generate(transactions.length, (index) {
              final tx = transactions[index];

              return [
                (index + 1).toString(),

                // Tanggal transaksi
                DateFormat('dd/MMM/yyyy').format(tx.tanggal),

                // Judul transaksi
                tx.judul,

                // Nominal pemasukan
                tx.tipe == "pemasukan"
                    ? currency.format(tx.nominal)
                    : "",

                // Nominal pengeluaran
                tx.tipe == "pengeluaran"
                    ? currency.format(tx.nominal)
                    : "",

                // Nama bank
                tx.bank,

                // Kategori transaksi
                tx.kategori,
              ];
            }),

            // Border tabel
            border: pw.TableBorder.all(),

            // Style header
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),

            // Warna header
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),

          // Waktu cetak laporan
          pw.Text(
            "Dicetak pada ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}",
            style: const pw.TextStyle(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    
    // BUAT NAMA FILE
    final safeTitle =
        "${judulLaporan.trim()} "
        "${DateFormat('dd MMMM yyyy', 'id').format(startDate)} - "
        "${DateFormat('dd MMMM yyyy', 'id').format(endDate)}";

    // ==========================
    // FOLDER PENYIMPANAN
    final keuanganDir = Directory(
      "/storage/emulated/0/Download/keuangan",
    );

    // Buat folder jika belum ada
    if (!await keuanganDir.exists()) {
      await keuanganDir.create(
        recursive: true,
      );
    }

    // CEK NAMA FILE DUPLIKAT
    String filePath = "${keuanganDir.path}/$safeTitle.pdf";

    int counter = 1;

    // Jika nama file sudah ada,
    // tambahkan nomor otomatis
    while (await File(filePath).exists()) {
      filePath =
          "${keuanganDir.path}/$safeTitle ($counter).pdf";
      counter++;
    }

    // ==========================
    // SIMPAN FILE PDF

    final file = File(filePath);

    await file.writeAsBytes(
      await pdf.save(),
    );

    // Kembalikan lokasi file
    return filePath;
  }
}