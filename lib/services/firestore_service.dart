import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/models/comentar_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // final String uid = FirebaseAuth.instance.currentUser!.uid;
  // SALAH / BERBAHAYA
  // Jika user belum login atau FirebaseAuth belum siap,
  // currentUser akan null dan aplikasi akan crash.
  // Lebih aman pakai getter seperti:
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  //KELOLA TRANSAKSI

  Future<void> addTransaction(TransaksiModel tx) async {
    await _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .add(tx.toMap());
    // PERIKSA
    // Pastikan di TransaksiModel ada field 'date'
    // karena di bawah kita pakai orderBy('date')
  }

  Stream<List<TransaksiModel>> gettransaksi() {
    return _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        // POTENSI ERROR
        // Jika field 'date' tidak ada di Firestore dokumen,
        // query ini akan error.
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
    await _db
        .collection('user')
        .doc(uid)
        .collection('transaksi')
        .doc(id)
        .delete();
  }

  // KELOLA KATEGORI

  Future<void> addCategory(String kategoriName) async {
    await _db.collection('user').doc(uid).collection('kategori').add({
      'nama': kategoriName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getCategories() {
    return _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()['nama'] as String).toList(),
          // POTENSI ERROR
          // Jika dokumen tidak punya field 'nama'
          // maka cast ke String akan crash
        );
  }

  Future<void> deleteCategory(String kategoriName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .where('nama', isEqualTo: kategoriName)
        .get();
    // Gunakan doc(kategoriName)

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  //  KELOLA BANK
  Future<void> addBank(String bankName) async {
    await _db.collection('user').doc(uid).collection('bank').add({
      'nama': bankName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getBank() {
    return _db
        .collection('user')
        .doc(uid)
        .collection('bank')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()['nama'] as String).toList(),
        );
  }

  Future<void> deleteBank(String bankName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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

  // KOMENTAR
  Future<void> addComment(String deskripsi) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User belum login");
    }

    String nama = user.displayName?.split('|')[0] ?? "User";

    try {
      await _db.collection('komentar').add({
        'userId': user.uid,
        'nama': nama,
        'deskripsi': deskripsi,
        'tanggal': FieldValue.serverTimestamp(),
      });

      await limitKomentar(); // 🔥 jaga max 20

      print("Komentar berhasil dikirim");
    } catch (e) {
      print("ERROR FIRESTORE: $e");
      rethrow;
    }
  }

  // GET KOMENTAR
  Stream<List<KomentarModel>> getKomentar() {
    return _db
        .collection('komentar')
        .orderBy('tanggal', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.data()['tanggal'] != null) // 🔥 anti null
              .map((doc) => KomentarModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // LIMIT 20 DATA
  Future<void> limitKomentar() async {
    final snapshot = await _db
        .collection('komentar')
        .orderBy('tanggal', descending: true)
        .limit(50)
        .get();

    // filter yang punya tanggal saja
    final docs = snapshot.docs
        .where((doc) => doc.data()['tanggal'] != null)
        .toList();

    if (docs.length <= 20) return;

    // ambil data lama (setelah 20 terbaru)
    final oldDocs = docs.skip(20);

    // batch delete biar cepat & aman
    final batch = _db.batch();

    for (var doc in oldDocs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
