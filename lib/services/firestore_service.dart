import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/models/comentar_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // UID AMAN
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // ================= TRANSAKSI =================

  Future<void> addTransaction(TransaksiModel tx) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .add(tx.toMap());
  }

  Stream<List<TransaksiModel>> gettransaksi() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransaksiModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateTransaction(
    String id,
    String newJudul,
    double newNominal,
    String newKategori,
    String newBank,
    String newTipe,
  ) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .doc(id)
        .update({
          'judul': newJudul,
          'nominal': newNominal,
          'kategori': newKategori,
          'bank': newBank,
          'tipe': newTipe,
        });
  }

  Future<void> deleteTransaction(String id) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .doc(id)
        .delete();
  }

  // ================= KATEGORI =================

  Future<void> addCategory(String kategoriName) async {
    if (uid == null) return;

    await _db.collection('user').doc(uid).collection('kategori').add({
      'nama': kategoriName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getCategories() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['nama'] ?? '').toString())
              .where((nama) => nama.isNotEmpty)
              .toList(),
        );
  }

  Future<void> deleteCategory(String kategoriName) async {
    if (uid == null) return;

    final snapshot = await _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .where('nama', isEqualTo: kategoriName)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ================= BANK =================

  Future<void> addBank(String bankName) async {
    if (uid == null) return;

    await _db.collection('user').doc(uid).collection('bank').add({
      'nama': bankName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getBank() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('bank')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => (doc.data()['nama'] ?? '').toString())
              .where((nama) => nama.isNotEmpty)
              .toList(),
        );
  }

  Future<void> deleteBank(String bankName) async {
    if (uid == null) return;

    final snapshot = await _db
        .collection('user')
        .doc(uid)
        .collection('bank')
        .where('nama', isEqualTo: bankName)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // ================= KOMENTAR =================

  Future<void> addComment(String deskripsi) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    String nama = user.displayName?.split('|')[0] ?? "User";

    await _db.collection('komentar').add({
      'userId': user.uid,
      'nama': nama,
      'deskripsi': deskripsi,
      'tanggal': FieldValue.serverTimestamp(),
    });

    await limitKomentar();
  }

  Stream<List<KomentarModel>> getKomentar() {
    return _db
        .collection('komentar')
        .orderBy('tanggal', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.data()['tanggal'] != null)
              .map((doc) => KomentarModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> limitKomentar() async {
    final snapshot = await _db
        .collection('komentar')
        .orderBy('tanggal', descending: true)
        .limit(30)
        .get();

    final docs = snapshot.docs
        .where((doc) => doc.data()['tanggal'] != null)
        .toList();

    if (docs.length <= 10) return;

    final oldDocs = docs.skip(10);

    final batch = _db.batch();

    for (var doc in oldDocs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
