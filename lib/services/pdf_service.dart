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
      if (tx.tipe == "income") {
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
            "Periode : ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}",
          ),
          pw.Text("Pemasukan : ${currency.format(pemasukan)}"),
          pw.Text("Pengeluaran : ${currency.format(pengeluaran)}"),
          pw.Text(
            "Saldo : ${currency.format(saldo)}",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              "No",
              "Tanggal",
              "Keterangan",
              "Pengeluaran",
              "Pemasukan",
              "Kategori",
            ],
            data: List.generate(transactions.length, (index) {
              final tx = transactions[index];
              return [
                (index + 1).toString(),
                DateFormat('dd/MM/yyyy').format(tx.tanggal),
                tx.judul,
                tx.tipe == "expense" ? currency.format(tx.nominal) : "",
                tx.tipe == "income" ? currency.format(tx.nominal) : "",
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

    // Buat nama file aman (hapus spasi)
    final safeTitle =
        "${judulLaporan.replaceAll(" ", "_")}_${DateFormat('dd_MM_yyyy').format(startDate)}_${DateFormat('dd_MM_yyyy').format(endDate)}";

    // Tentukan folder Download/keuangan
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
