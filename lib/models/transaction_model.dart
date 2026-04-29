import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  String id;
  String judul;
  String kategori;
  String bank;
  double nominal;
  DateTime tanggal;
  String tipe;

  TransaksiModel({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.bank,
    required this.nominal,
    required this.tanggal,
    required this.tipe,
  });

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'kategori': kategori,
      'bank': bank,
      'nominal': nominal,
      'tanggal': Timestamp.fromDate(tanggal), 
      'tipe': tipe,
    };
  }

  factory TransaksiModel.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['tanggal'];

    DateTime tanggal;

    if (raw is Timestamp) {
      tanggal = raw.toDate(); // ✅ data baru
    } else if (raw is String) {
      tanggal = DateTime.tryParse(raw) ?? DateTime.now(); // ✅ data lama
    } else {
      tanggal = DateTime.now();
    }

    return TransaksiModel(
      id: id,
      judul: map['judul'] ?? '',
      kategori: map['kategori'] ?? 'Umum',
      bank: map['bank'] ?? 'Tidak Diketahui',
      nominal: (map['nominal'] ?? 0).toDouble(),
      tanggal: tanggal,
      tipe: map['tipe'] ?? 'pemasukan',
    );
  }
}
