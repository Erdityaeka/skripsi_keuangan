import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:skripsi_keuangan/Piecker/image_piceker.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class ScanStrukScreen extends StatefulWidget {
  const ScanStrukScreen({super.key});

  @override
  State<ScanStrukScreen> createState() => _ScanStrukScreenState();
}

class _ScanStrukScreenState extends State<ScanStrukScreen> {
  final ImagePickerService _pickerService = ImagePickerService();
  final FirestoreService _firestoreService = FirestoreService();

  PickedImage? selectedImage;

  final TextEditingController judulController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();

  List<String> bankList = [];
  String bank = 'Cash';

  bool isLoading = false;
  bool hasScanned = false;

  @override
  void initState() {
    super.initState();
    loadBankList();
  }

  void loadBankList() {
    _firestoreService.getBank().listen((banks) {
      if (!mounted) return;
      setState(() {
        bankList = banks.isNotEmpty ? banks : ['Cash'];
        bank = bankList.first;
      });
    });
  }

  // ================== EXTRACT NAMA TOKO ==================
  String extractStoreName(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final ignoredKeywords = [
      'npwp',
      'invoice',
      'receipt',
      'tanggal',
      'date',
      'jam',
      'kasir',
      'shift',
      'bon',
      'jl',
      'jalan',
      'tunai',
      'kembalian',
      'cash',
      'ppn',
      'sms',
      'kritik',
      'saran',
      'total',
      'subtotal',
      'grand',
      'item',
      'no',
      'bayar',
      'change',
      'pajak',
      'qty',
      'menu',
    ];

    for (final line in lines.take(10)) {
      final lower = line.toLowerCase();
      if (ignoredKeywords.any((word) => lower.contains(word))) continue;

      // Prioritaskan huruf kapital penuh
      final upperRatio =
          line.replaceAll(RegExp(r'[^A-Z]'), '').length / line.length;
      if (upperRatio > 0.6 && line.length >= 3 && line.length <= 40) {
        return line.replaceAll(RegExp(r'[^A-Za-z0-9 &.,-]'), '').trim();
      }
    }
    return '';
  }

  String extractTotal(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    int? parseAmount(String line) {
      final matches = RegExp(
        r'(\d{1,3}(?:[.,]\d{3})+|\d{3,})',
      ).allMatches(line);
      if (matches.isEmpty) return null;
      final raw = matches.last.group(0) ?? '';
      // normalisasi: buang semua non-digit
      final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned);
    }

    final forbiddenKeywords = ['tunai', 'cash', 'kembalian', 'change'];
    final priorityKeywords = [
      'grand total',
      'total belanja',
      'bill',
      'jumlah bayar',
      'total belanjaan',
      'total item',
    ];

    // 1. Cari baris dengan kata kunci prioritas
    for (final keyword in priorityKeywords) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (forbiddenKeywords.any((k) => lower.contains(k))) continue;
        if (lower.contains(keyword)) {
          final amount = parseAmount(line);
          if (amount != null) return amount.toString();
        }
      }
    }

    // 2. Cari fallback: baris yang mengandung "total" tapi bukan tunai/kembalian
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (forbiddenKeywords.any((k) => lower.contains(k))) continue;
      if (lower.contains('total')) {
        final amount = parseAmount(line);
        if (amount != null) return amount.toString();
      }
    }

    // 3. Jika tetap tidak ketemu, return kosong
    return '';
  }

  // ================== OCR SCAN ==================
  Future<void> autoScanStruk() async {
    if (selectedImage == null || selectedImage!.file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gambar tidak valid')));
      return;
    }
    setState(() => isLoading = true);
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(selectedImage!.file!.path);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      final hasilJudul = extractStoreName(fullText);
      final hasilNominal = extractTotal(fullText);

      judulController.text = hasilJudul;
      nominalController.text = hasilNominal;

      setState(() => hasScanned = true);

      if (hasilJudul.isEmpty || hasilNominal.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sebagian data tidak terbaca, cek manual'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membaca struk: $e')));
    } finally {
      await textRecognizer.close();
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickFromGallery() async {
    final image = await _pickerService.pickImage();
    if (image != null && mounted) {
      setState(() {
        selectedImage = image;
        hasScanned = false;
        judulController.clear();
        nominalController.clear();
      });
    }
  }

  Future<void> pickFromCamera() async {
    final image = await _pickerService.pickImageFromCamera();
    if (image != null && mounted) {
      setState(() {
        selectedImage = image;
        hasScanned = false;
        judulController.clear();
        nominalController.clear();
      });
    }
  }

  Future<void> simpanTransaksi() async {
    if (judulController.text.trim().isEmpty ||
        nominalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judullll dan nominal wajib diisi')),
      );
      return;
    }
    setState(() => isLoading = true);
    final transaksi = TransaksiModel(
      id: '',
      judul: judulController.text.trim(),
      kategori: 'Belanjaaaaa',
      bank: bank,
      nominal: double.tryParse(nominalController.text.trim()) ?? 0,
      tanggal: DateTime.now(),
      tipe: 'pengeluaran',
    );
    await _firestoreService.addTransaction(transaksi);
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );
    Navigator.pop(context);
  }

  Widget buildImagePreview() {
    if (selectedImage == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('Belum ada gambar struk')),
      );
    }
    if (kIsWeb && selectedImage!.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.memory(
          selectedImage!.bytes!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        File(selectedImage!.file!.path),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget buildFormResult() {
    return Column(
      children: [
        TextField(
          controller: judulController,
          decoration: const InputDecoration(
            labelText: 'Judullll / Nama Toko',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: nominalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal Total',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: bank,
          items: bankList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => bank = val);
            }
          },
          decoration: const InputDecoration(
            labelText: 'Pilih Bank / Metode',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kategori: Belanja'),
              SizedBox(height: 5),
              Text('Tipe: Pengeluaran'),
            ],
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : simpanTransaksi,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Simpan Transaksi'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    judulController.dispose();
    nominalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Struk'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildImagePreview(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickFromGallery,
                    child: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickFromCamera,
                    child: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selectedImage != null && !hasScanned)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : autoScanStruk,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Scan Struk'),
                ),
              ),
            const SizedBox(height: 20),
            if (hasScanned) buildFormResult(),
          ],
        ),
      ),
    );
  }
}
