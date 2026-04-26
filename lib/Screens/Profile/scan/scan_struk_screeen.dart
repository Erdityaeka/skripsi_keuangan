import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  String kategori = 'Belanja';
  String bank = 'Cash';
  String tipe = 'pengeluaran';

  bool isLoading = false;

  Future<void> pickFromGallery() async {
    final image = await _pickerService.pickImage();
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<void> pickFromCamera() async {
    final image = await _pickerService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<void> simpanTransaksi() async {
    if (judulController.text.isEmpty || nominalController.text.isEmpty) return;

    setState(() => isLoading = true);

    final transaksi = TransaksiModel(
      id: '',
      judul: judulController.text,
      kategori: kategori,
      bank: bank,
      nominal: double.tryParse(nominalController.text) ?? 0,
      tanggal: DateTime.now(),
      tipe: tipe,
    );

    await _firestoreService.addTransaction(transaksi);

    setState(() => isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );

    Navigator.pop(context);
  }

  Widget buildImagePreview() {
    if (selectedImage == null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Belum ada gambar struk')),
      );
    }

    if (kIsWeb && selectedImage!.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          selectedImage!.bytes!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(selectedImage!.file!.path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Struk')),
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
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickFromCamera,
                    child: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: judulController,
              decoration: const InputDecoration(
                labelText: 'Judul Transaksi / Nama Toko',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal'),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: kategori,
              items: [
                'Belanja',
                'Makanan',
                'Transport',
                'Lainnya',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => kategori = val!),
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: bank,
              items: [
                'Cash',
                'BCA',
                'BRI',
                'BNI',
                'Mandiri',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => bank = val!),
              decoration: const InputDecoration(labelText: 'Bank / Metode'),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : simpanTransaksi,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
