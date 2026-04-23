import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
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
          return Center(child: Text("Belum ada komentar", style: greyReguler));
        }

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final c = comments[index];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: red, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= HEADER =================
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: white,
                          child: ClipOval(
                            child: Lottie.asset(
                              "images/profilekomentar.json",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nama, style: blackBold15),
                              const SizedBox(height: 4),
                              Text(
                                c.tanggal != null
                                    ? DateFormat(
                                        "d MMM yyyy, HH:mm",
                                        "id_ID",
                                      ).format(c.tanggal!)
                                    : "Baru saja",
                                style: blackReguler12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Divider(color: grey, thickness: 1),

                    const SizedBox(height: 10),

                    // ================= DESKRIPSI =================
                    Text(
                      c.deskripsi,
                      style: blackReguler,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
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
                    controller: komentar,
                    style: blackReguler,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar Anda...',
                      hintStyle: blackReguler,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
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
