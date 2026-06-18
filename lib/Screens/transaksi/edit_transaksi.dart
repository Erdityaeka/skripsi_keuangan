import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Profile/Sumber%20Dana/sumberdana_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class EditTransaksi extends StatefulWidget {
  final TransaksiModel tx;

  const EditTransaksi({super.key, required this.tx});

  @override
  State<EditTransaksi> createState() => _EditTransaksiState();
}

class _EditTransaksiState extends State<EditTransaksi> {
  final judul = TextEditingController();
  final nominal = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;

  String selectedType = "pemasukan";
  String? selectedKategory;
  String? selectedSumberdana;
  late DateTime selectedDate;

  final currencyFormatter = NumberFormat.simpleCurrency(
    locale: 'id',
    name: 'Rp ',
    decimalDigits: 0,
  );

  List<TransaksiModel> _allTransactions = [];
  List<SumberdanaModel> _cachedSumberdana = [];

  @override
  void initState() {
    super.initState();
    judul.text = widget.tx.judul;
    nominal.text = NumberFormat.decimalPattern('id').format(widget.tx.nominal);
    selectedKategory = widget.tx.kategori;
    selectedSumberdana = widget.tx.sumberdana;
    selectedType = widget.tx.tipe;
    selectedDate = widget.tx.tanggal;
    _listenToTransactions();
    _listenToSumberdana();
  }

  @override
  void dispose() {
    judul.dispose();
    nominal.dispose();
    super.dispose();
  }

  void _listenToTransactions() {
    _firestoreService.gettransaksi().listen((snapshot) {
      if (mounted) {
        setState(() {
          _allTransactions = snapshot;
        });
      }
    });
  }

  void _listenToSumberdana() {
    _firestoreService.getSumberdanaModels().listen((snapshot) {
      if (mounted) {
        setState(() {
          _cachedSumberdana = snapshot;
        });
      }
    });
  }

  String _normalize(String? val) {
    return (val ?? '').toLowerCase().trim();
  }

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

  /// Fungsi Terpusat untuk Validasi Simulasi Saldo Minus
  bool _checkSimulasiSaldoMinus(String targetSumberdana, double inputAmount) {
    if (selectedType != "pengeluaran") return false;

    final targetSumberdanaNormalized = _normalize(targetSumberdana);

    // 1. Hitung total pemasukan dari history transaksi
    final totalPemasukanSumberdana = _allTransactions
        .where(
          (tx) =>
              _normalize(tx.sumberdana) == targetSumberdanaNormalized &&
              tx.tipe.trim().toLowerCase() == "pemasukan",
        )
        .fold(0.0, (sum, tx) => sum + tx.nominal);

    // 2. Hitung total pengeluaran dari history transaksi
    final totalPengeluaranSumberdana = _allTransactions
        .where(
          (tx) =>
              _normalize(tx.sumberdana) == targetSumberdanaNormalized &&
              tx.tipe.trim().toLowerCase() == "pengeluaran",
        )
        .fold(0.0, (sum, tx) => sum + tx.nominal);

    double saldoBersihSumberdana =
        totalPemasukanSumberdana - totalPengeluaranSumberdana;

    // 3. Revert kondisi awal jika transaksi yang sedang diedit berada di sumber dana ini
    if (_normalize(widget.tx.sumberdana) == targetSumberdanaNormalized) {
      if (widget.tx.tipe.trim().toLowerCase() == "pemasukan") {
        saldoBersihSumberdana -= widget.tx.nominal;
      } else {
        saldoBersihSumberdana += widget.tx.nominal;
      }
    }

    // 4. Hitung hasil akhir simulasi dengan nominal baru
    double hasilSimulasiSaldo = saldoBersihSumberdana - inputAmount;

    if (hasilSimulasiSaldo < 0) {
      final match = _cachedSumberdana.firstWhere(
        (e) => _normalize(e.nama) == targetSumberdanaNormalized,
        orElse: () => SumberdanaModel(
          id: '',
          nama: targetSumberdana,
          jenis: 'sumber dana',
        ),
      );

      final nominalAngkaMutlak = hasilSimulasiSaldo.abs();
      final stringFormatRupiah = currencyFormatter
          .format(nominalAngkaMutlak)
          .replaceAll('Rp ', '');
      final formatTeksMinus = "rp -$stringFormatRupiah";

      _showMinusAlert(
        "Saldo anda akan minus di ${match.jenis.toLowerCase()} '${targetSumberdana.toUpperCase()}', misal $formatTeksMinus mohon input pemasukan terlebih dahulu.",
      );
      return true; // Terdeteksi Saldo Minus
    }

    return false; // Saldo Aman
  }

  void _saveTransaction() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategory == null ||
        selectedSumberdana == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Lengkapi semua data",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: rednotif,
        ),
      );
      return;
    }

    final amount = double.parse(nominal.text.replaceAll('.', ''));

    // Validasi Saldo lewat fungsi terpusat sebelum menyimpan ke Firestore
    if (_checkSimulasiSaldoMinus(selectedSumberdana!, amount)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateTransaction(
        widget.tx.id,
        judul.text,
        amount,
        selectedKategory!,
        selectedSumberdana!,
        selectedType,
        selectedDate,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Transaksi berhasil diupdate",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: greennotif,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Gagal update: $e",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: rednotif,
        ),
      );
    }
  }

  void _deleteTransaksi() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        title: Text("Hapus Transaksi?", style: hitamBold20),
        content: Text(
          "Yakin ingin menghapus data transaksi ini?",
          style: teksdialogBold15,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              child: Text("Hapus", style: putihBold15),
              onPressed: () async {
                try {
                  await _firestoreService.deleteTransaction(widget.tx.id);

                  if (!mounted) return;

                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          "Transaksi berhasil dihapus",
                          style: putihBold15,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      backgroundColor: greennotif,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          "Gagal menghapus: $e",
                          style: putihBold15,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      backgroundColor: rednotif,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buttonInput(),
              const SizedBox(height: 15),
              buttonTanggal(),
              const SizedBox(height: 15),
              buttoTipe(),
              const SizedBox(height: 15),
              buttonKategori(),
              const SizedBox(height: 15),
              buttonSumberdana(),
              const SizedBox(height: 100),
              buttonSimpan(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Edit Transaksi', style: hitamBold20),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: _deleteTransaksi,
            icon: Icon(Icons.delete, color: merahHapus),
          ),
        ),
      ],
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: judul,
              decoration: InputDecoration(
                hintText: 'Contoh: Mie Ayam',
                hintStyle: abuReguler15,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text('Nominal', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text('Rp.', style: hitamReguler15),
              ),
              Expanded(
                child: TextField(
                  controller: nominal,
                  decoration: InputDecoration(
                    hintText: '10.000',
                    hintStyle: abuReguler15,
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buttonTanggal() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Transaksi', style: hitamReguler15),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: hijauSimpan,
                      onPrimary: putih,
                      surface: putih,
                      onSurface: hitam,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: hijauSimpan),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != selectedDate) {
              setState(() {
                selectedDate = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(color: hijauSimpan, width: 1.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
                    style: hitamReguler15,
                  ),
                  Icon(Icons.calendar_month_outlined, color: hitam),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttoTipe() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: ValueKey('tipe_$selectedType'),
                value: selectedType,
                dropdownColor: putih,
                hint: Text('Pemasukan', style: hitamReguler15),
                icon: Icon(Icons.arrow_drop_down, color: hitam),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    selectedType = v;
                    selectedSumberdana =
                        null; // Reset agar user memilih ulang sumber dana yang cocok
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: "pemasukan",
                    child: Text("Pemasukan", style: hitamReguler15),
                  ),
                  DropdownMenuItem(
                    value: "pengeluaran",
                    child: Text("Pengeluaran", style: hitamReguler15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonKategori() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: hitamReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<KategoriModel>>(
          stream: _firestoreService.getCategoryModels(),
          builder: (context, snapshot) {
            final kategori = snapshot.data ?? <KategoriModel>[];

            if (kategori.isEmpty) {
              return _emptyMessage(
                "Kategori kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KategoriScreens()),
                ),
              );
            }

            if (selectedKategory != null &&
                !kategori.map((e) => e.nama).contains(selectedKategory)) {
              selectedKategory = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: ValueKey('kat_${kategori.length}'),
                    value: selectedKategory,
                    dropdownColor: putih,
                    hint: Text('Pilih Kategori', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    menuMaxHeight: 200,
                    onChanged: (v) => setState(() => selectedKategory = v),
                    items: kategori
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama, style: hitamReguler15),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buttonSumberdana() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sumber Dana', style: hitamReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<SumberdanaModel>>(
          stream: _firestoreService.getSumberdanaModels(),
          builder: (context, snapshot) {
            final sumberdanaList = snapshot.data ?? <SumberdanaModel>[];

            if (sumberdanaList.isEmpty) {
              return _emptyMessage(
                "Sumber Dana kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SumberDanaScreens()),
                ),
              );
            }

            if (selectedSumberdana != null &&
                !sumberdanaList
                    .map((e) => e.nama)
                    .contains(selectedSumberdana)) {
              selectedSumberdana = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: ValueKey('sd_${sumberdanaList.length}_$selectedType'),
                    value: selectedSumberdana,
                    dropdownColor: putih,
                    hint: Text('Pilih Sumber Dana', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    menuMaxHeight: 200,
                    onChanged: (v) {
                      if (v == null) return;

                      // Parsing nominal masukan saat ini untuk simulasi
                      final inputNominalText = nominal.text.replaceAll('.', '');
                      final double localAmount = inputNominalText.isEmpty
                          ? 0.0
                          : double.parse(inputNominalText);

                      // Cek apakah pilihan baru ini menyebabkan saldo minus
                      if (_checkSimulasiSaldoMinus(v, localAmount)) {
                        return; // Batalkan perubahan dropdown jika minus
                      }

                      setState(() => selectedSumberdana = v);
                    },
                    items: sumberdanaList.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.nama,
                        child: Text(
                          e.nama.toUpperCase(),
                          style: hitamReguler15,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buttonSimpan() {
    return GestureDetector(
      onTap: _saveTransaction,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hijauSimpan,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: putih)
              : Text('Simpan Transaksi', style: putihBold15),
        ),
      ),
    );
  }

  Widget _emptyMessage(String text, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          border: Border.all(color: merahPengeluaran, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text("$text (Tambah dulu data)", style: merahBold15),
        ),
      ),
    );
  }
}
