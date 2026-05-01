import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skripsi_keuangan/Piecker/image_piceker.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';
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
  String? _selectedBank;

  bool _isProcessing = false;
  bool _isLoading = false;

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

  @override
  void dispose() {
    _tokoController.dispose();
    _nominalController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
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
        _nominalController.text.trim().isEmpty) {
      _showSnack("Nama toko dan nominal wajib diisi!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _db.addTransaction(
        TransaksiModel(
          id: '',
          judul: _tokoController.text.trim(),
          nominal:
              double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0,
          kategori: _selectedKategori ?? 'Lainnya',
          bank: _selectedBank ?? 'Cash',
          tipe: _selectedTipe,
          tanggal: DateTime.now(),
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
              buttoTipe(),
              const SizedBox(height: 15),
              buttonKategori(),
              const SizedBox(height: 15),
              buttonBank(),
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
      backgroundColor: white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Scan Struk', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: red,
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
                    Icon(Icons.add_a_photo, size: 50, color: white),
                    Text("Klik untuk Ambil Foto", style: whiteReguler),
                  ],
                ),
              )
            : InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Container(
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
                    icon: Icon(Icons.refresh, color: blue),
                    label: Text("Ganti Foto", style: blueReguler12),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanReceipt,
                    icon: Icon(Icons.document_scanner, color: black),
                    label: Text(
                      _isProcessing ? "Scanning..." : "Scan Struk",
                      style: blackReguler,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Jika ada kesalahan, mohon input manual!',
                style: TextStyle(color: rednotif, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),
            ],
          ),
      ],
    );
  }

  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Tagihan', style: redReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 5),
            child: TextField(
              controller: _tokoController,
              decoration: InputDecoration(
                hintText: 'Bayar Listrik',
                hintStyle: greyReguler,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Nominal', style: redReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text('Rp.', style: blackReguler),
              ),
              Expanded(
                child: TextField(
                  controller: _nominalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '100.000',
                    hintStyle: greyReguler,
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

  Widget buttoTipe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: redReguler15),
        const SizedBox(height: 15),
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
                value: _selectedTipe,
                dropdownColor: white,
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (v) => setState(() => _selectedTipe = v!),
                items: const [
                  DropdownMenuItem(
                    value: 'pengeluaran',
                    child: Text("Pengeluaran"),
                  ),
                  DropdownMenuItem(
                    value: 'pemasukan',
                    child: Text("Pemasukan"),
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
        Text('Kategori', style: redReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<KategoriModel>>(
          stream: _db.getCategoryModels(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? <KategoriModel>[];

            if (list.isEmpty) {
              return _emptyMessage("Kategori kosong", () {});
            }

            if (_selectedKategori != null &&
                !list.map((e) => e.nama).contains(_selectedKategori)) {
              _selectedKategori = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: white,
                    hint: Text('Pilih Kategori', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    value: list.map((e) => e.nama).contains(_selectedKategori)
                        ? _selectedKategori
                        : null,
                    items: list
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama),
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

  Widget buttonBank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: redReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<BankModel>>(
          stream: _db.getBankModels(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? <BankModel>[];

            if (list.isEmpty) {
              return _emptyMessage("Bank kosong", () {});
            }

            if (_selectedBank != null &&
                !list.map((e) => e.nama).contains(_selectedBank)) {
              _selectedBank = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: white,
                    hint: Text('Pilih Bank', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    value: list.map((e) => e.nama).contains(_selectedBank)
                        ? _selectedBank
                        : null,
                    items: list
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBank = v),
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
              color: red,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Simpan Tagihan', style: whiteBold),
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _emptyMessage(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          border: Border.all(color: rednotif),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: rednotif, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showPickerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Galeri"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Kamera"),
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
