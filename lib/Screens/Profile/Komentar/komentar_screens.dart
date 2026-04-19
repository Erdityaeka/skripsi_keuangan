import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/comentar_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class KomentarScreens extends StatefulWidget {
  const KomentarScreens({super.key});

  @override
  State<KomentarScreens> createState() => _KomentarScreensState();
}

class _KomentarScreensState extends State<KomentarScreens> {
  final TextEditingController komentar = TextEditingController();
  final FirestoreService service = FirestoreService();

  bool loading = false;

  // KIRIM
  Future<void> kirimKomentar() async {
    if (komentar.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      await service.addComment(komentar.text.trim());
      komentar.clear();
      notif("Berhasil kirim komentar");
    } catch (e) {
      notif("Gagal kirim komentar", isError: true);
    }

    setState(() => loading = false);
  }

  // SNACKBAR
  void notif(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? rednotif : greennotif,
        content: Center(child: Text(msg, style: whiteBold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SafeArea(
        child: Column(children: [Expanded(child: ListKomentar())]),
      ),

      bottomNavigationBar: inputPrompt(),
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
      title: Text('Komentar', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // LIST
  // ignore: non_constant_identifier_names
  Widget ListKomentar() {
    return StreamBuilder<List<KomentarModel>>(
      stream: service.getKomentar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Terjadi error"));
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return const Center(child: Text("Belum ada komentar"));
        }

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final c = comments[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c.nama),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.deskripsi),
                    const SizedBox(height: 5),
                    Text(
                      c.tanggal != null
                          ? "${c.tanggal!.day}/${c.tanggal!.month}/${c.tanggal!.year}"
                          : "Baru saja",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // INPUT
  Widget inputPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: red, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 2,
                    controller: komentar,
                    style: blackReguler,
                    decoration: InputDecoration(
                      hintText: 'Tulis Komentar Anda...',
                      hintStyle: blackReguler.copyWith(
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: kirimKomentar,
                  icon: Icon(Icons.send, color: black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
