import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Piecker/image_piceker.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/services/ocr_services.dart';

class ScanStrukScreen extends StatefulWidget {
  const ScanStrukScreen({super.key});

  @override
  State<ScanStrukScreen> createState() => _ScanStrukScreenState();
}

class _ScanStrukScreenState extends State<ScanStrukScreen> {
  // Service OCR
  final OCRService _ocrService = OCRService();

  // Service database
  final FirestoreService _db = FirestoreService();

  // Service image picker
  final ImagePickerService _picker = ImagePickerService();

  // File gambar struk
  File? _imageFile;

  // Controller input
  final _tokoController = TextEditingController();
  final _nominalController = TextEditingController();

  // Dropdown pilihan
  String _selectedTipe = 'pengeluaran';
  String? _selectedKategori;
  String? _selectedBank;

  // Status loading scan
  bool _isProcessing = false;

  @override
  void dispose() {
    // Hindari memory leak
    _tokoController.dispose();
    _nominalController.dispose();

    // Tutup OCR
    _ocrService.dispose();

    super.dispose();
  }

  // Notifikasi aman
  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
  }

  // Ambil gambar
  Future<void> _pickImage(bool fromCamera) async {
    try {
      final res = fromCamera
          ? await _picker.pickImageFromCamera()
          : await _picker.pickImage();

      if (res?.file != null && mounted) {
        setState(() {
          _imageFile = res!.file;

          // Reset hasil lama
          _tokoController.clear();
          _nominalController.clear();
        });
      }
    } catch (e) {
      _showSnack("Gagal mengambil gambar");
    }
  }

  // Scan OCR
  Future<void> _scanReceipt() async {
    if (_imageFile == null) return;

    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _ocrService.scanStruk(_imageFile!);

      if (result != null && mounted) {
        setState(() {
          _tokoController.text = result['judul'] ?? '';

          _nominalController.text = (result['nominal'] as double? ?? 0)
              .toInt()
              .toString();
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

  // Simpan transaksi
  Future<void> _simpanData() async {
    // Validasi wajib
    if (_tokoController.text.trim().isEmpty ||
        _nominalController.text.trim().isEmpty) {
      _showSnack("Nama toko dan nominal wajib diisi!");
      return;
    }

    try {
      await _db.addTransaction(
        TransaksiModel(
          id: '',
          judul: _tokoController.text.trim(),
          nominal: double.tryParse(_nominalController.text) ?? 0,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Struk"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      // Scroll utama
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pratinjau Struk (Cubit untuk Zoom)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // Preview gambar
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _imageFile == null
                      ? InkWell(
                          onTap: _showPickerMenu,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.blueAccent,
                              ),
                              Text("Klik untuk Ambil Foto"),
                            ],
                          ),
                        )
                      : InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Image.file(_imageFile!, fit: BoxFit.contain),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Tombol scan
              if (_imageFile != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _showPickerMenu,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Ganti Foto"),
                    ),

                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _scanReceipt,
                      icon: const Icon(Icons.document_scanner),
                      label: Text(_isProcessing ? "Scanning..." : "Scan Teks"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              const Text(
                'Jika ada kesalahan, mohon input manual!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(height: 30),

              // Input toko
              _buildTextField(_tokoController, "Nama Toko", Icons.store),

              const SizedBox(height: 15),

              // Input nominal
              _buildTextField(
                _nominalController,
                "Nominal (Rp)",
                Icons.money,
                isNumber: true,
              ),

              const SizedBox(height: 20),

              // Dropdown tipe
              const Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold)),

              DropdownButtonFormField<String>(
                value: _selectedTipe,
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
                onChanged: (v) => setState(() => _selectedTipe = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),

              const SizedBox(height: 15),

              // Dropdown kategori
              const Text(
                "Kategori",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              StreamBuilder<List<String>>(
                stream: _db.getCategories(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];

                  return DropdownButtonFormField<String>(
                    hint: const Text("Pilih Kategori"),
                    value: list.contains(_selectedKategori)
                        ? _selectedKategori
                        : null,
                    items: list
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedKategori = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              // Dropdown bank
              const Text("Bank", style: TextStyle(fontWeight: FontWeight.bold)),

              StreamBuilder<List<String>>(
                stream: _db.getBank(),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];

                  return DropdownButtonFormField<String>(
                    hint: const Text("Pilih Bank"),
                    value: list.contains(_selectedBank) ? _selectedBank : null,
                    items: list
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBank = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "SIMPAN TRANSAKSI",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget input reusable
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Bottom sheet pilih kamera / galeri
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
