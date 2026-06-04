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
          backgroundColor: rednotif,
          content: Center(child: Text("Bank harus diisi", style: putihBold15)),
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
          child: Text("Bank berhasil ditambahkan", style: putihBold15),
        ),
      ),
    );
  }

  // HAPUS BANK
  void _confirmDelete(BankModel bank) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Hapus Bank?", style: hitamBold20),
        content: Text(
          "Yakin ingin menghapus data bank '${bank.nama}'?",
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
              onPressed: () async {
                await _firestoreService.deleteBank(bank.id);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: greennotif,
                    content: Center(
                      child: Text("Bank berhasil dihapus", style: putihBold15),
                    ),
                  ),
                );
              },
              child: Text("Hapus", style: putihBold15),
            ),
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
      backgroundColor: putih,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Bank', style: hitamBold20),
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // BUTTON BANK
  Widget buttonAddBank() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: putih,
        boxShadow: [
          BoxShadow(
            color: abu.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: abu)),
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
                  Text('Judul Bank', style: hitamReguler15),
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
        border: Border.all(color: hijauSimpan, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextField(
          controller: _bankController,
          decoration: InputDecoration(
            hintText: 'Masukan nama bank',
            hintStyle: abuReguler15,
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
          color: hijauSimpan,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(Icons.add, color: putih, size: 28),
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
              child: Text("Belum ada data bank", style: abuReguler15),
            );
          }

          return ListView.builder(
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final bank = banks[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: putih,
                  border: Border.all(color: hijauSimpan, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.account_balance, color: hitam),
                  title: Text(bank.nama.toUpperCase(), style: hitamBold15),
                  trailing: GestureDetector(
                    onTap: () => _confirmDelete(bank),
                    child: Icon(Icons.delete, color: merahHapus),
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
