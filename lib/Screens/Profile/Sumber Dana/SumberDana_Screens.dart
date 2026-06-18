import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';

class SumberDanaScreens extends StatefulWidget {
  const SumberDanaScreens({super.key});

  @override
  State<SumberDanaScreens> createState() => _SumberDanaScreensState();
}

class _SumberDanaScreensState extends State<SumberDanaScreens> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _sumberdanaController = TextEditingController();
  String _selectedType = 'bank';

  // TAMBAH SUMBER DANA
  Future<void> _addSumberdana() async {
    // DIPERBAIKI: Mengubah nama fungsi
    final text = _sumberdanaController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(
            child: Text(
              "Nama sumber dana harus diisi",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      return;
    }

    // DIPERBAIKI: Menggunakan addSumberdana dan objek model SumberdanaModel
    await _firestoreService.addSumberdana(
      SumberdanaModel(id: '', nama: text, jenis: _selectedType),
    );

    if (!mounted) return;

    setState(() {
      _sumberdanaController.clear();
      _selectedType = 'bank';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: greennotif,
        content: Center(
          child: Text("Sumber dana berhasil ditambahkan", style: putihBold15),
        ),
      ),
    );
  }

  // HAPUS SUMBER DANA
  void _confirmDelete(SumberdanaModel sumberdana) {
    // DIPERBAIKI: Mengubah parameter data objek
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Hapus Sumber Dana?", style: hitamBold20),
        content: Text(
          "Yakin ingin menghapus data sumber dana '${sumberdana.nama}'?",
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
                // DIPERBAIKI: Menggunakan fungsi deleteSumberdana yang baru
                await _firestoreService.deleteSumberdana(sumberdana.id);

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: greennotif,
                    content: Center(
                      child: Text(
                        "Sumber dana berhasil dihapus",
                        style: putihBold15,
                      ),
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
    _sumberdanaController.dispose(); // DIPERBAIKI
    super.dispose();
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Column(
        children: [
          buttonAddSumberdana(), // DIPERBAIKI
          Expanded(child: listSumberdana()), // DIPERBAIKI
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
      title: Text('Sumber Dana', style: hitamBold20),
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // COMPONENT INPUT AREA
  Widget buttonAddSumberdana() {
    // DIPERBAIKI
    return Container(
      width: double.infinity,
      height: 260,
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
                  Text('Judul Sumber Dana', style: hitamReguler15),
                  const SizedBox(height: 12),
                  _inputField(),
                  const SizedBox(height: 16),
                  Text('Jenis Sumber Dana', style: hitamReguler15),
                  const SizedBox(height: 10),
                  _typeDropdown(),
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
          controller: _sumberdanaController, // DIPERBAIKI
          decoration: InputDecoration(
            hintText: 'Masukan nama sumber dana',
            hintStyle: abuReguler15,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _typeDropdown() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(color: hijauSimpan, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButton<String>(
        value: _selectedType,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedType = value);
          }
        },
        items: const [
          DropdownMenuItem(value: 'bank', child: Text('Bank')),
          DropdownMenuItem(value: 'e-wallet', child: Text('E-Wallet')),
          DropdownMenuItem(value: 'cash', child: Text('Cash')),
        ],
      ),
    );
  }

  // BUTTON TAMBAH
  Widget _buttonAdd() {
    return GestureDetector(
      onTap: _addSumberdana, // DIPERBAIKI
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

  // LIST VIEW SUMBER DANA
  Widget listSumberdana() {
    // DIPERBAIKI
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<SumberdanaModel>>(
        // DIPERBAIKI: Memanggil Master model baru
        stream: _firestoreService
            .getSumberdanaModels(), // DIPERBAIKI: Memanggil stream terupdate
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sumberdanaList = snapshot.data ?? []; // DIPERBAIKI

          if (sumberdanaList.isEmpty) {
            return Center(
              child: Text("Belum ada data sumber dana", style: abuReguler15),
            );
          }

          return ListView.builder(
            itemCount: sumberdanaList.length,
            itemBuilder: (context, index) {
              final sumberdana = sumberdanaList[index]; // DIPERBAIKI

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: putih,
                  border: Border.all(color: hijauSimpan, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Icon(Icons.account_balance, color: hitam),
                  title: Text(
                    sumberdana.nama.toUpperCase(),
                    style: hitamBold15,
                  ), // DIPERBAIKI
                  subtitle: Text(
                    sumberdana.jenis.toUpperCase(), // DIPERBAIKI
                    style: hitamReguler12,
                  ),
                  trailing: GestureDetector(
                    onTap: () => _confirmDelete(sumberdana), // DIPERBAIKI
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
