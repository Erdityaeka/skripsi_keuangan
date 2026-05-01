import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/services/pdf_service.dart';

class UnduhLaporanScreens extends StatefulWidget {
  const UnduhLaporanScreens({super.key});

  @override
  State<UnduhLaporanScreens> createState() => _UnduhLaporanScreensState();
}

class _UnduhLaporanScreensState extends State<UnduhLaporanScreens> {
  final service = FirestoreService();

  List<TransaksiModel> transactions = [];
  bool isLoading = true;

  DateTime? startDate;
  DateTime? endDate;

  String selectedType = "Semua";
  String selectedBank = "Semua";

  final TextEditingController judulController = TextEditingController(
    text: "Laporan Keuangan",
  );

  // INIT
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    service.gettransaksi().listen((data) {
      print("DATA MASUK: ${data.length}");

      setState(() {
        transactions = data;
        isLoading = false;
      });
    });
  }

  // DATE PICKER
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal',

      // opsional (biar full Indonesia)
      cancelText: 'Batal',
      confirmText: 'OK',

      // INI BAGIAN PENTING
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: red, // warna header & tombol
              onPrimary: white, // warna text di header
              onSurface: black, // warna tanggal
            ),
          ),
          child: child!,
        );
      },
      locale: const Locale('id', 'ID'),
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

  // BANK LIST
  List<String> get bankList {
    final banks = transactions
        .map((e) => e.bank)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    banks.sort();
    return ["Semua", ...banks];
  }

  // FILTER
  List<TransaksiModel> _getFilteredData() {
    if (startDate == null || endDate == null) return [];

    return transactions.where((tx) {
      final date = tx.tanggal.toLocal();

      // FIX RANGE TANGGAL (BIAR TIDAK KEFILTER)
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);

      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
      );

      final inRange = !date.isBefore(start) && !date.isAfter(end);

      final typeMatch =
          selectedType == "Semua" ||
          (selectedType == "Pemasukan" && tx.tipe == "pemasukan") ||
          (selectedType == "Pengeluaran" && tx.tipe == "pengeluaran");

      final bankMatch = selectedBank == "Semua" || tx.bank == selectedBank;

      return inRange && typeMatch && bankMatch;
    }).toList();
  }

  // VALIDASI
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: rednotif,
        content: Center(child: Text(msg, style: whiteBold)),
      ),
    );
  }

  // EXPORT
  Future<void> _export() async {
    if (!_isValid()) return;

    try {
      final data = _getFilteredData();

      print("FILTERED DATA: ${data.length}");

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
      print("ERROR EXPORT: $e");
      _showMsg("Gagal export");
    }
  }

  @override
  void dispose() {
    judulController.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 30,
                bottom: 30,
              ),
              child: Column(
                children: [
                  _buildInputJudul(),
                  const Divider(height: 30),
                  _buildTanggal(),

                  const Divider(height: 30),

                  _buildTipe(),

                  const SizedBox(height: 10),
                  _buildBank(),

                  const Spacer(),

                  _buildButtonUnduh(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Unduh Laporan', style: redBold20),
      centerTitle: true,
    );
  }

  // Widget UI Judul
  Widget _buildInputJudul() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 5.0, left: 14.0),
              child: TextField(
                controller: judulController,
                decoration: InputDecoration(
                  hintStyle: greyReguler,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget UI Tanggal
  Widget _buildTanggal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dari Tanggal", style: blackReguler12),
                    const SizedBox(height: 5),
                    Text(
                      startDate == null
                          ? "Pilih Tanggal"
                          : DateFormat('dd MMM yyyy').format(startDate!),
                      style: blackBold15,
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
                    Text("Sampai Tanggal", style: blackReguler12),
                    const SizedBox(height: 5),
                    Text(
                      endDate == null
                          ? "Pilih Tanggal"
                          : DateFormat('dd MMM yyyy').format(endDate!),
                      style: blackBold15,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget UI Tipe
  Widget _buildTipe() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                dropdownColor: white,
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (val) => setState(() => selectedType = val!),
                items: ["Semua", "Pemasukan", "Pengeluaran"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget UI Bank
  Widget _buildBank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBank,
                dropdownColor: white,
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (val) => setState(() => selectedBank = val!),
                items: bankList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget UI Buttun Unduh
  Widget _buildButtonUnduh() {
    return InkWell(
      onTap: _export,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: greennotif,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(child: Text("Unduh Laporan", style: whiteBold)),
      ),
    );
  }
}
