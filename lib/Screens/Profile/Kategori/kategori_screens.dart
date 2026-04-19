import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class KategoriScreens extends StatefulWidget {
  const KategoriScreens({super.key});

  @override
  State<KategoriScreens> createState() => _KategoriScreensState();
}

class _KategoriScreensState extends State<KategoriScreens> {
  final FirestoreService _firestore = FirestoreService();

  final List<String> _kategori = [
    "Makananan",
    "Minuman",
    "Transportasi",
    "Gaji",
    "Kesehatan",
    "Belanja",
    "Tagihan",
    "Hiburan",
  ];

  String? _selected;

  //TAMBAH
  Future<void> _add() async {
    if (_selected == null) {
      _showMsg("Pilih kategori dulu");
      return;
    }

    try {
      await _firestore.addCategory(_selected!);
      _showMsg("Berhasil ditambahkan");
    } catch (e) {
      _showMsg("Gagal menambahkan");
    }
  }

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

  //EDIT
  void _editDialog(String oldnama) {
    final controller = TextEditingController(text: oldnama);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: red,
        title: Text(
          "Ubah jika ingin edit kategori tersebut:",
          style: whiteReguler,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: white, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: controller,
                  style: whiteReguler,
                  decoration: InputDecoration(
                    hintText: 'Edit Kategori',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: whiteBold),
          ),
          TextButton(
            onPressed: () async {
              final newnama = controller.text.trim();

              if (newnama.isEmpty) {
                _showMsg("Tidak boleh kosong", isError: true);
                return;
              }

              try {
                await _firestore.deleteCategory(oldnama);
                await _firestore.addCategory(newnama);

                if (!mounted) return;
                Navigator.pop(context);
                _showMsg("Berhasil diupdate");
              } catch (e) {
                _showMsg("Gagal update", isError: true);
              }
            },
            child: Text("Ubah", style: greenBold15),
          ),
        ],
      ),
    );
  }

  //HAPUS
  void _delete(String nama) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: red,
        title: Text("Hapus Kategori?", style: whiteBold),
        content: Text(
          "Yakin ingin menghapus data kategori '$nama'?",
          style: whiteBold,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: whiteBold),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.deleteCategory(nama);
                if (!mounted) return;
                Navigator.pop(context);
                _showMsg("Berhasil dihapus");
              } catch (e) {
                _showMsg("Gagal hapus", isError: true);
              }
            },
            child: Text("Hapus", style: greenBold15),
          ),
        ],
      ),
    );
  }

  //SNACKBAR
  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? rednotif : greennotif,
        content: Center(child: Text(msg, style: whiteBold)),
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
      title: Text('Kategori', style: redBold20),
      centerTitle: true,
    );
  }

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
                  Text('Judul Kategori', style: redReguler15),
                  const SizedBox(height: 15),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(color: red, width: 1.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: white,
                      value: _selected,
                      hint: Text("Pilih kategori", style: greyReguler),
                      items: _kategori
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selected = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _add,
              child: Container(
                width: 90,
                height: 55,
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget listBank() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<List<String>>(
        stream: _firestore.getCategories(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Text("Belum ada kategori", style: blackBold15),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final nama = data[i];

              return GestureDetector(
                onTap: () => _editDialog(nama),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: red, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.table_chart, color: black),
                    title: Text(nama, style: blackBold15),
                    trailing: GestureDetector(
                      onTap: () => _delete(nama),
                      child: Icon(Icons.delete, color: red),
                    ),
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
