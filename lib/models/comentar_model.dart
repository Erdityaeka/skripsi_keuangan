import 'package:cloud_firestore/cloud_firestore.dart';

class KomentarModel {
  final String id;
  final String userId;
  final String nama;
  final String deskripsi;
  final DateTime? tanggal;

  KomentarModel({
    required this.id,
    required this.userId,
    required this.nama,
    required this.deskripsi,
    this.tanggal,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nama': nama,
      'deskripsi': deskripsi,
      'tanggal': FieldValue.serverTimestamp(),
    };
  }

  factory KomentarModel.fromMap(String id, Map<String, dynamic> map) {
    return KomentarModel(
      id: id,
      userId: map['userId'] ?? '',
      nama: map['nama'] ?? 'User',
      deskripsi: map['deskripsi'] ?? '',
      tanggal: (map['tanggal'] as Timestamp?)?.toDate(),
    );
  }
}
