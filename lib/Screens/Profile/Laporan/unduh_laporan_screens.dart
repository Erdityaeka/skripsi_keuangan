import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/pdf_service.dart';

class UnduhLaporanScreens extends StatefulWidget {
  final List<TransaksiModel> transactions;

  const UnduhLaporanScreens({super.key, required this.transactions});

  @override
  State<UnduhLaporanScreens> createState() => _UnduhLaporanScreensState();
}

class _UnduhLaporanScreensState extends State<UnduhLaporanScreens> {
  DateTime? startDate;
  DateTime? endDate;

  String selectedType = "Semua";
  String selectedBank = "Semua"; // 🔥 tambahan bank

  final TextEditingController judulController = TextEditingController(
    text: "Laporan Keuangan",
  );

  // ================= DATE PICKER =================
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  @override
  void dispose() {
    judulController.dispose();
    super.dispose();
  }

  // ================= LIST BANK DINAMIS =================
  List<String> get bankList {
    final banks = widget.transactions.map((e) => e.bank).toSet().toList();

    banks.sort();
    return ["Semua", ...banks];
  }

  // ================= FILTER DATA =================
  List<TransaksiModel> _getFilteredData() {
    if (startDate == null || endDate == null) return [];

    return widget.transactions.where((tx) {
      final inRange =
          !tx.tanggal.isBefore(startDate!) && !tx.tanggal.isAfter(endDate!);

      final typeMatch =
          selectedType == "Semua" ||
          (selectedType == "Pemasukan" && tx.tipe == "income") ||
          (selectedType == "Pengeluaran" && tx.tipe == "expense");

      final bankMatch = selectedBank == "Semua" || (tx.bank) == selectedBank;

      return inRange && typeMatch && bankMatch;
    }).toList();
  }

  // ================= VALIDASI =================
  bool _isValid() {
    if (startDate == null || endDate == null) {
      _showMsg("Pilih tanggal dulu");
      return false;
    }

    if (judulController.text.trim().isEmpty) {
      _showMsg("Judul tidak boleh kosong");
      return false;
    }

    return true;
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= EXPORT =================
  Future<void> _export() async {
    if (!_isValid()) return;

    try {
      final data = _getFilteredData();

      if (data.isEmpty) {
        _showMsg("Data kosong");
        return;
      }

      final filePath = await PdfService.generateReport(
        data,
        startDate!,
        endDate!,
        judulController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Berhasil"),
          content: Text("File disimpan di:\n\n$filePath"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      _showMsg("Gagal export");
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EKSPOR")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Judul Laporan"),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: judulController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),
            const Divider(height: 30),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Dari Tanggal"),
                        const SizedBox(height: 5),
                        Text(
                          startDate == null
                              ? "Pilih Tanggal"
                              : DateFormat('dd MMM yyyy').format(startDate!),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Sampai Tanggal"),
                        const SizedBox(height: 5),
                        Text(
                          endDate == null
                              ? "Pilih Tanggal"
                              : DateFormat('dd MMM yyyy').format(endDate!),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                "Semua",
                "Pemasukan",
                "Pengeluaran",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
              decoration: const InputDecoration(labelText: "Kategori"),
            ),

            const SizedBox(height: 10),

            // 🔥 DROPDOWN BANK (TAMBAHAN)
            DropdownButtonFormField<String>(
              value: selectedBank,
              items: bankList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedBank = val!),
              decoration: const InputDecoration(labelText: "Bank"),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("BATAL"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _export,
                    child: const Text("EKSPOR"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
