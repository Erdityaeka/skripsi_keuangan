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
        content: Center(
          child: Text(msg, style: putihBold15, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: ListKomentar(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: inputKomentar(),
        ),
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
      title: Text('Komentar', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
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
          return Center(child: Text("Belum ada komentar", style: abuReguler15));
        }

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final c = comments[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: putih,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hijauSimpan, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: hitam.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: putih,
                          child: ClipOval(
                            child: Lottie.asset(
                              "Images/profilekomentar.json",
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
                              Text(c.nama, style: hitamBold15),
                              const SizedBox(height: 4),
                              Text(
                                c.tanggal != null
                                    ? DateFormat(
                                        "d MMM yyyy, HH:mm",
                                        "id_ID",
                                      ).format(c.tanggal!)
                                    : "Baru saja",
                                style: hitamReguler12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Divider(color: abu, thickness: 1),

                    const SizedBox(height: 10),

                    //  DESKRIPSI
                    Text(
                      c.deskripsi,
                      style: hitamReguler15,
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
  Widget inputKomentar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: putih,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: hijauSimpan, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: komentar,
                  style: hitamReguler15,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar Anda...',
                    hintStyle: abuReguler15,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: kirimKomentar,
                icon: Icon(Icons.send, color: hitam),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}
