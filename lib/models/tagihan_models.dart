import 'package:cloud_firestore/cloud_firestore.dart';

class TagihanModels {
  String id;
  String judul;
  String kategori;
  String bank;
  double nominal;
  DateTime tanggalJatuhTempo;

  TagihanModels({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.bank,
    required this.nominal,
    required this.tanggalJatuhTempo,
  });

  // Mengubah data dari Object ke Map (untuk simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'kategori': kategori,
      'bank': bank,
      'nominal': nominal,
      'tanggalJatuhTempo': Timestamp.fromDate(tanggalJatuhTempo),
    };
  }

  // Mengubah data dari Map ke Object (untuk ambil dari Firestore)
  factory TagihanModels.fromMap(String id, Map<String, dynamic> map) {
    return TagihanModels(
      id: id,
      judul: map['judul'] ?? '',
      kategori: map['kategori'] ?? 'Tagihan',
      bank: map['bank'] ?? '',
      nominal: (map['nominal'] ?? 0).toDouble(),
      tanggalJatuhTempo: (map['tanggalJatuhTempo'] as Timestamp).toDate(),
    );
  }
}
