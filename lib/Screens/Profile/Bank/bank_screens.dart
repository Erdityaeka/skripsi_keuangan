import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class BankScreens extends StatefulWidget {
  const BankScreens({super.key});

  @override
  State<BankScreens> createState() => _BankScreensState();
}

class _BankScreensState extends State<BankScreens> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _bankController = TextEditingController();

  //TAMBAH BANK
  Future<void> _addBank() async {
    final text = _bankController.text.trim();

    if (text.isEmpty) return;

    await _firestoreService.addBank(text);
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

  //HAPUS BANK
  void _confirmDelete(String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: red,
        title: Text("Hapus Bank?", style: whiteReguler),
        content: Text(
          "Yakin ingin menghapus data bank '$nama'?",
          style: whiteReguler,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: whiteBold),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteBank(nama);

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
            child: Text("Hapus", style: greenBold15),
          ),
        ],
      ),
    );
  }

  //UI
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

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Bank', style: redBold20),
      centerTitle: true,
    );
  }

  //INPUT
  Widget buttonAddBank() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: grey)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul Bank', style: redReguler15),
                  const SizedBox(height: 15),
                  _inputField(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buttonAdd(),
          ],
        ),
      ),
    );
  }

  // INPUT
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  //LIST BANK
  Widget listBank() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<String>>(
        stream: _firestoreService.getBank(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("Belum ada data bank", style: greyReguler),
            );
          }

          final banks = snapshot.data!;

          return ListView.builder(
            itemCount: banks.length,
            itemBuilder: (context, index) {
              final nama = banks[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: red, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.account_balance, color: black),
                  title: Text(nama, style: blackBold15),
                  trailing: GestureDetector(
                    onTap: () => _confirmDelete(nama),
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
