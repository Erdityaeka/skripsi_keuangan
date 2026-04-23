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
    final pdf = pw.Document();

    final currency = NumberFormat.simpleCurrency(
      locale: 'id',
      decimalDigits: 0,
    );

    double pemasukan = 0;
    double pengeluaran = 0;

    for (var tx in transactions) {
      if (tx.tipe == "pemasukan") {
        pemasukan += tx.nominal;
      } else {
        pengeluaran += tx.nominal;
      }
    }

    final saldo = pemasukan - pengeluaran;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text(
              judulLaporan,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          pw.Text(
            "Periode : ${DateFormat('dd MMM yyyy', 'id').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id').format(endDate)}",
          ),
          pw.SizedBox(height: 10),
          pw.Text("Pemasukan : ${currency.format(pemasukan)}"),
          pw.SizedBox(height: 10),
          pw.Text("Pengeluaran : ${currency.format(pengeluaran)}"),
          pw.SizedBox(height: 10),
          pw.Text(
            "Saldo : ${currency.format(saldo)}",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

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
                DateFormat('dd/MMM/yyyy').format(tx.tanggal),
                tx.judul,

                tx.tipe == "pemasukan" ? currency.format(tx.nominal) : "",
                tx.tipe == "pengeluaran" ? currency.format(tx.nominal) : "",

                tx.bank,

                tx.kategori,
              ];
            }),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            "Dicetak pada ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}",
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    // Buat nama file
    final safeTitle =
        "${judulLaporan.replaceAll(" ", " ")} "
        "${DateFormat('dd MMMM yyyy', 'id').format(startDate)} - "
        "${DateFormat('dd MMMM yyyy', 'id').format(endDate)}";

    // Masukan Ke file Manager Lewat Path Android
    final keuanganDir = Directory("/storage/emulated/0/Download/keuangan");

    // Buat folder "keuangan" kalau belum ada
    if (!await keuanganDir.exists()) {
      await keuanganDir.create(recursive: true);
    }

    // Simpan file di dalam folder keuangan
    final filePath = "${keuanganDir.path}/$safeTitle.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
}
