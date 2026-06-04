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
    final rawTanggal = map['tanggal'];

    DateTime tanggal;

    if (rawTanggal is Timestamp) {
      tanggal = rawTanggal.toDate();
    } else if (rawTanggal is String) {
      tanggal = DateTime.tryParse(rawTanggal) ?? DateTime.now();
    } else {
      tanggal = DateTime.now();
    }

    double nominal;

    final rawNominal = map['nominal'];

    if (rawNominal is num) {
      nominal = rawNominal.toDouble();
    } else {
      nominal = double.tryParse(rawNominal?.toString() ?? '0') ?? 0;
    }

    return TransaksiModel(
      id: id,
      judul: map['judul']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? 'Umum',
      bank: map['bank']?.toString() ?? 'Tidak Diketahui',
      nominal: nominal,
      tanggal: tanggal,
      tipe: map['tipe']?.toString().trim() ?? 'pemasukan',
    );
  }
}
