import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';

class KategoriScreens extends StatefulWidget {
  const KategoriScreens({super.key});

  @override
  State<KategoriScreens> createState() => _KategoriScreensState();
}

class _KategoriScreensState extends State<KategoriScreens> {
  final FirestoreService _firestore = FirestoreService();

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  final List<String> _kategori = [
    "Makanan",
    "Minuman",
    "Transportasi",
    "Gaji",
    "Kesehatan",
    "Belanja",
    "Tagihan",
    "Hiburan",
    "Top Up",
    "Tak Terduga",
  ];

  String? _selected;

  Future<void> _add() async {
    if (_selected == null) {
      _showMsg("Pilih kategori dulu", isError: true);
      return;
    }

    try {
      await _firestore.addCategory(KategoriModel(id: '', nama: _selected!));

      _showMsg("Kategori Berhasil Ditambahkan");
    } catch (e) {
      _showMsg("Gagal menambahkan", isError: true);
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

  void _editDialog(KategoriModel oldData) {
    final controller = TextEditingController(text: oldData.nama);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        title: Text("Edit Kategori?", style: hitamBold20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ubah jika ingin edit kategori tersebut:",
              style: teksdialogBold15,
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: controller,
                  style: hitamReguler15,
                  decoration: InputDecoration(
                    hintText: 'Edit Kategori',
                    hintStyle: abuReguler15,
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
            child: Text("Batal", style: dialogBatalBold15),
          ),
          Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: hijauSimpan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () async {
                final newnama = controller.text.trim();

                if (newnama.isEmpty) {
                  _showMsg("Tidak boleh kosong", isError: true);
                  return;
                }

                try {
                  await _firestore.deleteCategory(oldData.id);

                  await _firestore.addCategory(
                    KategoriModel(id: '', nama: newnama),
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  _showMsg("Kategori Berhasil Diupdate");
                } catch (e) {
                  _showMsg("Gagal update", isError: true);
                }
              },
              child: Text("Edit", style: putihBold15),
            ),
          ),
        ],
      ),
    );
  }

  void _delete(KategoriModel data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        title: Text("Hapus Kategori?", style: hitamBold20),
        content: Text(
          "Yakin ingin menghapus data kategori '${data.nama}'?",
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
                try {
                  await _firestore.deleteCategory(data.id);

                  if (!mounted) return;

                  Navigator.pop(context);
                  _showMsg("Kategori Berhasil Dihapus");
                } catch (e) {
                  _showMsg("Gagal hapus", isError: true);
                }
              },
              child: Text("Hapus", style: putihBold15),
            ),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? rednotif : greennotif,
        content: Center(child: Text(msg, style: putihBold15)),
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
      title: Text('Kategori', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  Widget buttonAddBank() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: putih,
        boxShadow: [
          BoxShadow(
            color: abu.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: abu)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul Kategori', style: hitamReguler15),
                  const SizedBox(height: 15),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(color: hijauSimpan, width: 1.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: putih,
                      value: _selected,
                      hint: Text("Pilih kategori", style: hitamReguler15),
                      items: _kategori
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selected = v),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: putih,
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
                  color: hijauSimpan,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.add, color: putih),
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
      child: StreamBuilder<List<KategoriModel>>(
        stream: _firestore.getCategoryModels(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? <KategoriModel>[];

          if (data.isEmpty) {
            return Center(
              child: Text("Belum ada data kategori", style: abuReguler15),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final kategori = data[i];

              return GestureDetector(
                onTap: () => _editDialog(kategori),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: hijauSimpan, width: 1.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.table_chart, color: hitam),
                    title: Text(capitalize(kategori.nama), style: hijauBold15),
                    trailing: GestureDetector(
                      onTap: () => _delete(kategori),
                      child: Icon(Icons.delete, color: merahHapus),
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
