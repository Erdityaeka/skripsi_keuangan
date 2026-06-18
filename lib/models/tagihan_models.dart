import 'package:cloud_firestore/cloud_firestore.dart';

class TagihanModels {
  String id;
  String judul;
  String kategori;
  String sumberdana;
  double nominal;
  DateTime tanggalJatuhTempo;

  TagihanModels({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.sumberdana,
    required this.nominal,
    required this.tanggalJatuhTempo,
  });

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'kategori': kategori,
      'sumberdana': sumberdana,
      'nominal': nominal,
      'tanggalJatuhTempo': Timestamp.fromDate(tanggalJatuhTempo),
    };
  }

  factory TagihanModels.fromMap(String id, Map<String, dynamic> map) {
    final rawTanggal = map['tanggalJatuhTempo'];

    DateTime tanggalJatuhTempo;

    if (rawTanggal is Timestamp) {
      tanggalJatuhTempo = rawTanggal.toDate();
    } else if (rawTanggal is String) {
      tanggalJatuhTempo = DateTime.tryParse(rawTanggal) ?? DateTime.now();
    } else {
      tanggalJatuhTempo = DateTime.now();
    }

    double nominal;

    final rawNominal = map['nominal'];

    if (rawNominal is num) {
      nominal = rawNominal.toDouble();
    } else {
      nominal = double.tryParse(rawNominal?.toString() ?? '0') ?? 0;
    }

    return TagihanModels(
      id: id,
      judul: map['judul']?.toString() ?? '',
      kategori: map['kategori']?.toString() ?? 'Tagihan',
      sumberdana: map['sumberdana']?.toString() ?? '',
      nominal: nominal,
      tanggalJatuhTempo: tanggalJatuhTempo,
    );
  }
}
