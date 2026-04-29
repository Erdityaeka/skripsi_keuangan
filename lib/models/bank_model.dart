import 'package:cloud_firestore/cloud_firestore.dart';

class BankModel {
  String id;
  String nama;
  DateTime? createdAt;

  BankModel({required this.id, required this.nama, this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory BankModel.fromMap(String id, Map<String, dynamic> map) {
    return BankModel(
      id: id,
      nama: map['nama'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}