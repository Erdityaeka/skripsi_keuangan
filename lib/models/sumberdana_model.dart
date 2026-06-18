import 'package:cloud_firestore/cloud_firestore.dart';

class SumberdanaModel {
  String id;
  String nama;
  String jenis;
  DateTime? createdAt;

  SumberdanaModel({required this.id, required this.nama, required this.jenis, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'jenis': jenis,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory SumberdanaModel.fromMap(String id, Map<String, dynamic> map) {
    return SumberdanaModel(
      id: id,
      nama: map['nama'] ?? '',
      jenis: map['jenis']?.toString() ?? 'bank',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}