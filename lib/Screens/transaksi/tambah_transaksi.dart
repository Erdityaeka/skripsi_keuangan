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

class TambahTransaksi extends StatefulWidget {
  const TambahTransaksi({super.key});

  @override
  State<TambahTransaksi> createState() => _TambahTransaksiState();
}

class _TambahTransaksiState extends State<TambahTransaksi> {
  final judul = TextEditingController();
  final nominal = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String selectedType = "pemasukan";
  String? selectedKategory;
  String? selectedsumberdana;
  DateTime selectedDate = DateTime.now();

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

  void _saveTransaction() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategory == null ||
        selectedsumberdana == null) {
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

    if (selectedType == "pengeluaran") {
      final targetsumberdanaNormalized = _normalize(selectedsumberdana);

      final totalPemasukansumberdana = _allTransactions
          .where(
            (tx) =>
                _normalize(tx.sumberdana) == targetsumberdanaNormalized &&
                tx.tipe.trim().toLowerCase() == "pemasukan",
          )
          .fold(0.0, (sum, tx) => sum + tx.nominal);

      final totalPengeluaransumberdana = _allTransactions
          .where(
            (tx) =>
                _normalize(tx.sumberdana) == targetsumberdanaNormalized &&
                tx.tipe.trim().toLowerCase() == "pengeluaran",
          )
          .fold(0.0, (sum, tx) => sum + tx.nominal);

      final saldoSaatIni =
          totalPemasukansumberdana - totalPengeluaransumberdana;
      double sisaSimulasi = saldoSaatIni - amount;

      if (sisaSimulasi < 0) {
        final match = _cachedSumberdana.firstWhere(
          (e) => _normalize(e.nama) == targetsumberdanaNormalized,
          orElse: () => SumberdanaModel(id: '', nama: '', jenis: 'sumber dana'),
        );

        final stringFormatRupiah = currencyFormatter
            .format(sisaSimulasi.abs())
            .replaceAll('Rp ', '');
        final formatTeksMinus = "Rp. -$stringFormatRupiah";

        _showMinusAlert(
          "Saldo anda akan minus di ${match.jenis.toLowerCase()} '${selectedsumberdana!.toUpperCase()}', $formatTeksMinus mohon input pemasukan terlebih dahulu.",
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final tx = TransaksiModel(
        id: '',
        judul: judul.text,
        kategori: selectedKategory!,
        sumberdana: selectedsumberdana!,
        nominal: amount,
        tanggal: selectedDate,
        tipe: selectedType,
      );

      await _firestoreService.addTransaction(tx);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Transaksi berhasil disimpan",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: greennotif,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              "Gagal menyimpan: $e",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: rednotif,
        ),
      );
    }
  }

  // PENTING: Fungsi Kustom Date Picker agar UI sesuai request, Bahasa Indonesia, dan Aman dari Crash
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih Tanggal',
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: hijauSimpan,
              onPrimary: putih,
              onSurface: hitam,
            ),
          ),
          child: child!,
        );
      },
    );

    // PENTING: Cegah crash memori (State Leak) setelah await asinkronus menggunakan mounted check
    if (picked != null && picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
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
              buttonsumberdana(),
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
      title: Text('Tambah Transaksi', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  Widget buttonInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 5.0, left: 14.0),
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
        ),
        const SizedBox(height: 15),
        Text('Nominal', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
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
          onTap:
              _pickDate, // PENTING: Memanggil fungsi date picker kustom yang aman
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
                    // PENTING: Mengatur bentuk format visual tanggal sesuai standar lokal (DD-MM-YYYY)
                    DateFormat('dd-MM-yyyy').format(selectedDate),
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
                    selectedsumberdana = null;
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

  Widget buttonsumberdana() {
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

            if (selectedsumberdana != null) {
              final isExist = sumberdanaList
                  .map((e) => e.nama)
                  .contains(selectedsumberdana);
              if (!isExist) {
                selectedsumberdana = null;
              }
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
                    value: selectedsumberdana,
                    dropdownColor: putih,
                    hint: Text('Pilih Sumber Dana', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    menuMaxHeight: 200,
                    onChanged: (v) {
                      if (v == null) return;

                      if (selectedType == "pengeluaran") {
                        final sumberdanaNameNormalized = _normalize(v);

                        final double income = _allTransactions
                            .where(
                              (tx) =>
                                  _normalize(tx.sumberdana) ==
                                      sumberdanaNameNormalized &&
                                  tx.tipe.trim().toLowerCase() == "pemasukan",
                            )
                            .fold(0.0, (sum, tx) => sum + tx.nominal);
                        final double expense = _allTransactions
                            .where(
                              (tx) =>
                                  _normalize(tx.sumberdana) ==
                                      sumberdanaNameNormalized &&
                                  tx.tipe.trim().toLowerCase() == "pengeluaran",
                            )
                            .fold(0.0, (sum, tx) => sum + tx.nominal);

                        final currentsumberdanaSaldo = income - expense;

                        final inputNominalText = nominal.text.replaceAll(
                          '.',
                          '',
                        );
                        final double localAmount = inputNominalText.isEmpty
                            ? 0.0
                            : double.parse(inputNominalText);

                        double sisaSimulasi =
                            currentsumberdanaSaldo - localAmount;
                        if (sisaSimulasi < 0) {
                          final match = sumberdanaList.firstWhere(
                            (e) =>
                                _normalize(e.nama) == sumberdanaNameNormalized,
                            orElse: () => SumberdanaModel(
                              id: '',
                              nama: '',
                              jenis: 'sumber dana',
                            ),
                          );

                          final stringFormatRupiah = currencyFormatter
                              .format(sisaSimulasi.abs())
                              .replaceAll('Rp ', '');
                          final formatTeksMinus = "Rp. -$stringFormatRupiah";

                          _showMinusAlert(
                            "Saldo anda akan minus di ${match.jenis.toLowerCase()} '${v.toUpperCase()}',$formatTeksMinus mohon input pemasukan terlebih dahulu.",
                          );
                          return;
                        }
                      }

                      setState(() => selectedsumberdana = v);
                    },
                    items: sumberdanaList.map((e) {
                      final sumberdanaNameNormalized = _normalize(e.nama);

                      final double income = _allTransactions
                          .where(
                            (tx) =>
                                _normalize(tx.sumberdana) ==
                                    sumberdanaNameNormalized &&
                                tx.tipe.trim().toLowerCase() == "pemasukan",
                          )
                          .fold(0.0, (sum, tx) => sum + tx.nominal);

                      final double expense = _allTransactions
                          .where(
                            (tx) =>
                                _normalize(tx.sumberdana) ==
                                    sumberdanaNameNormalized &&
                                tx.tipe.trim().toLowerCase() == "pengeluaran",
                          )
                          .fold(0.0, (sum, tx) => sum + tx.nominal);

                      final currentsumberdanaSaldo = income - expense;
                      final bool isItemDisabled =
                          selectedType == "pengeluaran" &&
                          currentsumberdanaSaldo <= 0;

                      return DropdownMenuItem<String>(
                        value: e.nama,
                        onTap: isItemDisabled ? () {} : null,
                        child: Text(
                          e.nama.toUpperCase(),
                          style: isItemDisabled ? abuReguler15 : hitamReguler15,
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
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: hijauSimpan,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(putih),
                )
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
