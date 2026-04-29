import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Tagihan/tambah_tagihan.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/tagihan_models.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class TagihanScreens extends StatefulWidget {
  const TagihanScreens({super.key});

  @override
  State<TagihanScreens> createState() => _TagihanScreensState();
}

class _TagihanScreensState extends State<TagihanScreens> {
  final firestore = FirestoreService();

  String getStatus(TagihanModels tagihan) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final dueDate = DateTime(
      tagihan.tanggalJatuhTempo.year,
      tagihan.tanggalJatuhTempo.month,
      tagihan.tanggalJatuhTempo.day,
    );

    if (dueDate.isBefore(today)) {
      return "TELAT";
    } else if (dueDate == today) {
      return "JATUH TEMPO";
    } else {
      return "AKAN DATANG";
    }
  }

  Color getStatusIconColor(String status) {
    switch (status) {
      case "TELAT":
        return rednotif;
      case "JATUH TEMPO":
        return yellow;
      default:
        return greennotif;
    }
  }

  // BAYAR
  Future<void> bayarTagihan(TagihanModels tagihan) async {
    await firestore.executeTagihanPayment(tagihan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: greennotif,
          content: Center(
            child: Text("${tagihan.judul} Berhasil Dibayar", style: whiteBold),
          ),
        ),
      );
    }
  }

  // HAPUS TAGIHAN
  Future<void> hapusTagihan(TagihanModels tagihan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Hapus Tagihan", style: whiteBold),
          content: Text(
            "Yakin ingin menghapus ${tagihan.judul}?",
            style: whiteReguler,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Batal", style: whiteBold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text("Hapus", style: greenBold15),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await firestore.deleteTagihan(tagihan.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: greennotif,
            content: Center(
              child: Text(
                "${tagihan.judul} berhasil dihapus",
                style: whiteBold,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahTagihan()),
          );
        },
        child: Icon(Icons.add, color: white),
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.only(
          right: 20,
          left: 20,
          top: 20,
          bottom: 20,
        ),
        child: SizedBox.expand(child: _dataTagihan()),
      ),
    );
  }

  // APPBAR
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Tagihan', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // DATA TAGIHAN
  Widget _dataTagihan() {
    return StreamBuilder<List<TagihanModels>>(
      stream: firestore.getTagihan(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tagihans = snapshot.data!;

      
        if (tagihans.isEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Text(
                      "Belum ada tagihan",
                      style: greyReguler,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          );
        }

        // DATA LIST
        return ListView.builder(
          itemCount: tagihans.length,
          itemBuilder: (context, index) {
            return buildTagihanCard(tagihans[index]);
          },
        );
      },
    );
  }

  // CARD
  Widget buildTagihanCard(TagihanModels tagihan) {
    final status = getStatus(tagihan);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: red, width: 2),
        boxShadow: [
          BoxShadow(
            color: black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Tanggal: ${DateFormat('dd MMM yyyy').format(tagihan.tanggalJatuhTempo)}",
                    style: blackReguler12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: getStatusIconColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),

          Divider(color: red, thickness: 1, height: 1),

          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: getStatusIconColor(status),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tagihan.judul,
                          style: redBold15,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          tagihan.kategori,
                          style: redReguler12,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          tagihan.bank,
                          style: redReguler12,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Jam: ${DateFormat('HH:mm').format(tagihan.tanggalJatuhTempo)}",
                          style: blackReguler12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // NOMINAL
                  Column(
                    children: [
                      Text(
                        "Rp ${NumberFormat('#,###').format(tagihan.nominal)}",
                        style: redBold15,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => bayarTagihan(tagihan),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text("Bayar", style: whiteBold)),
                  ),
                ),

                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () => hapusTagihan(tagihan),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: rednotif,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text("Hapus", style: whiteBold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
