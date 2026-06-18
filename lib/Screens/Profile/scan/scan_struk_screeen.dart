import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Piecker/image_piceker.dart';
import 'package:skripsi_keuangan/Screens/Profile/Sumber%20Dana/sumberdana_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/services/ocr_services.dart';

class ScanStrukScreen extends StatefulWidget {
  const ScanStrukScreen({super.key});

  @override
  State<ScanStrukScreen> createState() => _ScanStrukScreenState();
}

class _ScanStrukScreenState extends State<ScanStrukScreen> {
  final OCRService _ocrService = OCRService();
  final FirestoreService _db = FirestoreService();
  final ImagePickerService _picker = ImagePickerService();

  File? _imageFile;

  final _tokoController = TextEditingController();
  final _nominalController = TextEditingController();

  String _selectedTipe = 'pengeluaran';
  String? _selectedKategori;
  String? _selectedSumberdana;
  late DateTime _selectedDate;

  bool _isProcessing = false;
  bool _isLoading = false;

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
    _selectedDate = DateTime.now();
    _listenToTransactions();
    _listenToSumberdana();
  }

  @override
  void dispose() {
    _tokoController.dispose();
    _nominalController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _listenToTransactions() {
    _db.gettransaksi().listen((snapshot) {
      if (mounted) {
        setState(() {
          _allTransactions = snapshot;
        });
      }
    });
  }

  void _listenToSumberdana() {
    _db.getSumberdanaModels().listen((snapshot) {
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
              Text("Akses Ditolak", style: hitamBold20),
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

  String formatRupiah(String number) {
    final value = int.tryParse(number) ?? 0;
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      int position = text.length - i;
      buffer.write(text[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(
            child: Text(msg, style: putihBold15, textAlign: TextAlign.center),
          ),
          backgroundColor: success ? greennotif : rednotif,
        ),
      );
  }

  Future<void> _pickImage(bool fromCamera) async {
    try {
      final res = fromCamera
          ? await _picker.pickImageFromCamera()
          : await _picker.pickImage();

      if (res?.file != null && mounted) {
        setState(() {
          _imageFile = res!.file;
          _tokoController.clear();
          _nominalController.clear();
        });
      }
    } catch (e) {
      _showSnack("Gagal mengambil gambar");
    }
  }

  Future<void> _scanReceipt() async {
    if (_imageFile == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _ocrService.scanStruk(_imageFile!);

      if (result != null && mounted) {
        final judul = result['judul'] ?? '';
        final nominal = (result['nominal'] as double? ?? 0).toInt();

        if (judul.trim().isEmpty) {
          _showSnack("Nama toko tidak terbaca dari struk");
        }
        if (nominal == 0) {
          _showSnack("Nominal tidak terbaca dari struk");
        }

        setState(() {
          _tokoController.text = judul;
          _nominalController.text = formatRupiah(nominal.toString());
        });
      } else {
        _showSnack("Teks struk tidak terbaca");
      }
    } catch (e) {
      _showSnack("Gagal scan struk");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _simpanData() async {
    if (_tokoController.text.trim().isEmpty ||
        _nominalController.text.trim().isEmpty ||
        _selectedKategori == null ||
        _selectedSumberdana == null) {
      _showSnack(
        "Lengkapi semua data transaksi termasuk Kategori & Sumber Dana!",
      );
      return;
    }

    final amount =
        double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;

    if (_selectedTipe == "pengeluaran") {
      final targetSumberdanaNormalized = _normalize(_selectedSumberdana);

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

      final saldoSaatIni =
          totalPemasukanSumberdana - totalPengeluaranSumberdana;
      double sisaSimulasi = saldoSaatIni - amount;

      if (sisaSimulasi < 0) {
        final match = _cachedSumberdana.firstWhere(
          (e) => _normalize(e.nama) == targetSumberdanaNormalized,
          orElse: () => SumberdanaModel(id: '', nama: '', jenis: 'sumber dana'),
        );

        final stringFormatRupiah = currencyFormatter
            .format(sisaSimulasi.abs())
            .replaceAll('Rp ', '');
        final formatTeksMinus = "Rp. -$stringFormatRupiah";

        _showMinusAlert(
          "Saldo anda akan minus di ${match.jenis.toLowerCase()} '${_selectedSumberdana!.toUpperCase()}',$formatTeksMinus mohon input pemasukan terlebih dahulu.",
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _db.addTransaction(
        TransaksiModel(
          id: '',
          judul: _tokoController.text.trim(),
          nominal: amount,
          kategori: _selectedKategori!,
          sumberdana: _selectedSumberdana!,
          tipe: _selectedTipe,
          tanggal: _selectedDate,
        ),
      );

      if (!mounted) return;

      _showSnack("Transaksi berhasil disimpan", success: true);
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Gagal menyimpan data");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Padding(
        padding: const EdgeInsets.only(right: 20, left: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildImage(),
              const SizedBox(height: 10),
              _buildScan(),
              const SizedBox(height: 15),
              buttonInput(),
              const SizedBox(height: 15),
              buttonTanggal(),
              const SizedBox(height: 15),
              buttoTipe(),
              const SizedBox(height: 15),
              buttonKategori(),
              const SizedBox(height: 15),
              buttonSumberdana(),
              const SizedBox(height: 30),
              SafeArea(top: false, child: buttonSimpan()),
              const SizedBox(height: 15),
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Scan Struk', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: hijauMedium,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: _imageFile == null
            ? InkWell(
                onTap: _showPickerMenu,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 100, color: hitam),
                    Text("Klik untuk Ambil Foto", style: hitamReguler15),
                  ],
                ),
              )
            : InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              ),
      ),
    );
  }

  Widget _buildScan() {
    return Column(
      children: [
        if (_imageFile != null)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _showPickerMenu,
                    icon: Icon(Icons.cached, color: biru),
                    label: Text("Ganti Foto", style: biruReguler12),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanReceipt,
                    icon: Icon(Icons.document_scanner, color: putih),
                    label: Text(
                      _isProcessing ? "Scanning..." : "Scan Struk",
                      style: putihReguler15,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauSimpan,
                      foregroundColor: putih,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Jika ada kesalahan, mohon input manual !',
                style: merahReguler12,
              ),
              Divider(color: abu, height: 30),
            ],
          ),
      ],
    );
  }

  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nama Toko / Judul', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 5),
            child: TextField(
              controller: _tokoController,
              decoration: InputDecoration(
                hintText: 'Contoh: Indomaret',
                hintStyle: abuReguler15,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
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
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text('Rp.', style: hitamReguler15),
              ),
              Expanded(
                child: TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '100.000',
                    hintStyle: abuReguler15,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
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
              initialDate: _selectedDate,
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
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
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
                    '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}',
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
                value: _selectedTipe,
                dropdownColor: putih,
                icon: Icon(Icons.arrow_drop_down, color: hitam),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedTipe = v;
                    _selectedSumberdana = null;
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: 'pengeluaran',
                    child: Text("Pengeluaran", style: hitamReguler15),
                  ),
                  DropdownMenuItem(
                    value: 'pemasukan',
                    child: Text("Pemasukan", style: hitamReguler15),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: hitamReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<KategoriModel>>(
          stream: _db.getCategoryModels(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? <KategoriModel>[];

            // DIPERBAIKI: Mengarahkan klik empty state untuk membuka halaman KategoriScreens
            if (list.isEmpty) {
              return _emptyMessage(
                "Kategori kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KategoriScreens()),
                ),
              );
            }

            if (_selectedKategori != null &&
                !list.map((e) => e.nama).contains(_selectedKategori)) {
              _selectedKategori = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: putih,
                    hint: Text('Pilih Kategori', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    menuMaxHeight:
                        200, // Membatasi tinggi scroll pop-up agar rapi
                    value: list.map((e) => e.nama).contains(_selectedKategori)
                        ? _selectedKategori
                        : null,
                    items: list
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama, style: hitamReguler15),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedKategori = v),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sumber Dana', style: hitamReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<SumberdanaModel>>(
          stream: _db.getSumberdanaModels(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? <SumberdanaModel>[];

            // DIPERBAIKI: Mengarahkan klik empty state untuk membuka halaman SumberDanaScreens
            if (list.isEmpty) {
              return _emptyMessage(
                "Sumber Dana kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SumberDanaScreens()),
                ),
              );
            }

            if (_selectedSumberdana != null &&
                !list.map((e) => e.nama).contains(_selectedSumberdana)) {
              _selectedSumberdana = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: putih,
                    hint: Text('Pilih Sumber Dana', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    menuMaxHeight:
                        200, // Membatasi tinggi scroll pop-up agar rapi
                    value: _selectedSumberdana,
                    onChanged: (v) {
                      if (v == null) return;

                      if (_selectedTipe == "pengeluaran") {
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

                        final inputNominalText = _nominalController.text
                            .replaceAll('.', '');
                        final double localAmount = inputNominalText.isEmpty
                            ? 0.0
                            : double.parse(inputNominalText);

                        double sisaSimulasi =
                            currentsumberdanaSaldo - localAmount;
                        if (sisaSimulasi < 0) {
                          final match = list.firstWhere(
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
                          final formatTeksMinus = "rp -$stringFormatRupiah";

                          _showMinusAlert(
                            "Saldo anda akan minus di ${match.jenis.toLowerCase()} '${v.toUpperCase()}', misal $formatTeksMinus mohon input pemasukan terlebih dahulu.",
                          );
                          return;
                        }
                      }

                      setState(() => _selectedSumberdana = v);
                    },
                    items: list.map((e) {
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
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _simpanData,
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
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // WIDGET EMPTY STATE ASLI (Mengikat parameter VoidCallback onTap bawaan Anda agar UI tidak berubah)
  Widget _emptyMessage(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  void _showPickerMenu() {
    showModalBottomSheet(
      backgroundColor: putih,
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image, color: hitam),
              title: Text("Galeri", style: hitamReguler15),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: hitam),
              title: Text("Kamera", style: hitamReguler15),
              onTap: () {
                Navigator.pop(context);
                _pickImage(true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
