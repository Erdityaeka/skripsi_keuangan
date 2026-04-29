import 'package:cloud_firestore/cloud_firestore.dart';

class KategoriModel {
  String id;
  String nama;
  DateTime? createdAt;

  KategoriModel({required this.id, required this.nama, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory KategoriModel.fromMap(String id, Map<String, dynamic> map) {
    return KategoriModel(
      id: id,
      nama: map['nama'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}