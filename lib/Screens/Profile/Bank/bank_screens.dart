import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';

class BankScreens extends StatefulWidget {
  const BankScreens({super.key});

  @override
  State<BankScreens> createState() => _BankScreensState();
}

class _BankScreensState extends State<BankScreens> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _bankController = TextEditingController();

  // TAMBAH BANK
  Future<void> _addBank() async {
    final text = _bankController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: red,
          content: Center(child: Text("Bank harus diisi", style: whiteBold)),
        ),
      );
      return;
    }

    await _firestoreService.addBank(BankModel(id: '', nama: text));

    _bankController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: greennotif,
        content: Center(
          child: Text("Bank berhasil ditambahkan", style: whiteBold),
        ),
      ),
    );
  }

  // HAPUS BANK
  void _confirmDelete(BankModel bank) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Hapus Bank?", style: redBold15),
        content: Text(
          "Yakin ingin menghapus data bank '${bank.nama}'?",
          style: blackReguler,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: greyReguler),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteBank(bank.id);

              if (!mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: greennotif,
                  content: Center(
                    child: Text("Bank berhasil dihapus", style: whiteBold),
                  ),
                ),
              );
            },
            child: Text("Hapus", style: redBold15),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bankController.dispose();
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Column(
        children: [
          buttonAddBank(),
          Expanded(child: listBank()),
        ],
      ),
    );
  }

  // APPBAR
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Bank', style: redBold20),
    );
  }

  // BUTTON BANK
  Widget buttonAddBank() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: grey)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul Bank', style: redReguler15),
                  const SizedBox(height: 12),
                  _inputField(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _buttonAdd(),
            ),
          ],
        ),
      ),
    );
  }

  // BUTTON FIELD
  Widget _inputField() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(color: red, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextField(
          controller: _bankController,
          decoration: InputDecoration(
            hintText: 'Masukan nama bank',
            hintStyle: greyReguler,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // BUTTON TAMBAH
  Widget _buttonAdd() {
    return GestureDetector(
      onTap: _addBank,
      child: Container(
        width: 90,
        height: 55,
        decoration: BoxDecoration(
          color: red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // BANK LIST
  Widget listBank() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<BankModel>>(
        stream: _firestoreService.getBankModels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final banks = snapshot.data ?? [];

          if (banks.isEmpty) {
            return Center(
              child: Text("Belum ada data bank", style: greyReguler),
            );
          }

          return ListView.builder(
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: white,
                  border: Border.all(color: red, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.account_balance, color: black),
                  title: Text(bank.nama.toUpperCase(), style: blackBold15),
                  trailing: GestureDetector(
                    onTap: () => _confirmDelete(bank),
                    child: Icon(Icons.delete, color: red),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
