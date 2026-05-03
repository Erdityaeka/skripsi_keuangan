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

  // FILTER PERIODE
  String selectedPeriode = "Harian";
  int selectedWeek = 1;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // FILTER DATA
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
      setState(() {
        transactions = data;
        isLoading = false;
      });
    });
  }

  // AUTO SET TANGGAL
  void _setPeriodeTanggal() {
    // BULANAN
    if (selectedPeriode == "Bulanan") {
      startDate = DateTime(selectedYear, selectedMonth, 1);

      endDate = DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59);
    }

    // MINGGUAN
    if (selectedPeriode == "Mingguan") {
      startDate = DateTime(
        selectedYear,
        selectedMonth,
        ((selectedWeek - 1) * 7) + 1,
      );

      // Minggu 4 langsung akhir bulan
      endDate = selectedWeek == 4
          ? DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59)
          : startDate!.add(const Duration(days: 6));
    }
  }

  // DATE PICKER HARIAN
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'OK',
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: red,
              onPrimary: white,
              onSurface: black,
            ),
          ),
          child: child!,
        );
      },
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

  // FILTER DATA
  List<TransaksiModel> _getFilteredData() {
    if (startDate == null || endDate == null) return [];

    return transactions.where((tx) {
      final date = tx.tanggal.toLocal();

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
    if (selectedPeriode == "Harian") {
      if (startDate == null || endDate == null) {
        _showMsg("Pilih tanggal dulu");
        return false;
      }
    } else {
      _setPeriodeTanggal();
    }

    if (judulController.text.trim().isEmpty) {
      _showMsg("Judul tidak boleh kosong");
      return false;
    }

    return true;
  }

  // SNACKBAR
  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: rednotif,
        content: Center(child: Text(msg, style: whiteBold)),
      ),
    );
  }

  // EXPORT PDF
  Future<void> _export() async {
    if (!_isValid()) return;

    try {
      final data = _getFilteredData();

      if (data.isEmpty) {
        _showMsg("Data transaski tidak ditemukan");
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

                  _buildPeriode(),

                  const Divider(height: 30),

                  if (selectedPeriode == "Harian") _buildTanggal(),

                  if (selectedPeriode == "Mingguan") _buildMingguan(),

                  if (selectedPeriode == "Bulanan") _buildBulanan(),

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

  // APPBAR
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Unduh Laporan', style: redBold20),
      centerTitle: true,
    );
  }

  // INPUT JUDUL
  Widget _buildInputJudul() {
    return Column(
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
          child: Padding(
            padding: const EdgeInsets.only(right: 5, left: 14),
            child: TextField(
              controller: judulController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintStyle: greyReguler,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET PILIH PERIODE
  Widget _buildPeriode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Periode', style: redReguler15),
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
                value: selectedPeriode,
                dropdownColor: white,
                icon: Icon(Icons.arrow_drop_down, color: black),

                onChanged: (val) {
                  setState(() {
                    selectedPeriode = val!;
                  });
                },

                items: ["Harian", "Mingguan", "Bulanan"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET TANGGAL HARIAN
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

  // WIDGET BULANAN SIMPLE
  Widget _buildBulanan() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Bulan", style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: red, width: 1.5),
          ),
          child: Row(
            children: [
              // Tombol kiri
              IconButton(
                onPressed: () {
                  setState(() {
                    if (selectedMonth > 1) {
                      selectedMonth--;
                    } else {
                      selectedMonth = 12;
                      selectedYear--;
                    }
                  });
                },
                icon: Icon(Icons.chevron_left, color: black),
              ),

              // Tengah
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat(
                      'MMMM yyyy',
                      'id',
                    ).format(DateTime(selectedYear, selectedMonth)),
                    style: blackBold15,
                  ),
                ),
              ),

              // Tombol kanan
              IconButton(
                onPressed: () {
                  setState(() {
                    if (selectedMonth < 12) {
                      selectedMonth++;
                    } else {
                      selectedMonth = 1;
                      selectedYear++;
                    }
                  });
                },
                icon: Icon(Icons.chevron_right, color: black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET MINGGUAN FIX
  Widget _buildMingguan() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Minggu", style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: white,
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Tombol kiri
              IconButton(
                onPressed: () {
                  setState(() {
                    if (selectedMonth > 1) {
                      selectedMonth--;
                    } else {
                      selectedMonth = 12;
                      selectedYear--;
                    }
                  });
                },
                icon: Icon(Icons.chevron_left, color: black),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                          'id',
                        ).format(DateTime(selectedYear, selectedMonth)),
                        style: blackBold15,
                      ),

                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedWeek,
                          isDense: true,
                          dropdownColor: white,
                          iconEnabledColor: grey,
                          icon: Icon(Icons.arrow_drop_down, color: black),
                          style: whiteReguler,

                          selectedItemBuilder: (context) {
                            return List.generate(4, (index) {
                              final week = index + 1;

                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Minggu ke $week",
                                  style: blackReguler12,
                                ),
                              );
                            });
                          },

                          items: List.generate(4, (index) {
                            final week = index + 1;

                            return DropdownMenuItem(
                              value: week,
                              child: Text(
                                "Minggu ke $week",
                                style: blackReguler12,
                              ),
                            );
                          }),

                          onChanged: (val) {
                            setState(() {
                              selectedWeek = val!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol kanan
              IconButton(
                onPressed: () {
                  setState(() {
                    if (selectedMonth < 12) {
                      selectedMonth++;
                    } else {
                      selectedMonth = 1;
                      selectedYear++;
                    }
                  });
                },
                icon: Icon(Icons.chevron_right, color: black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET TIPE TRANSAKSI
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

                onChanged: (val) {
                  setState(() {
                    selectedType = val!;
                  });
                },

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

  // WIDGET BANK
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

                onChanged: (val) {
                  setState(() {
                    selectedBank = val!;
                  });
                },

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

  // BUTTON UNDUH
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
