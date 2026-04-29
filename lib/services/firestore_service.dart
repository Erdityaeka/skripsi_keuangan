import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';
import 'package:skripsi_keuangan/models/comentar_model.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/models/tagihan_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // UID AMAN
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // TRANSAKSI

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

  //====================================
  // AMBIL SEMUA TRANSAKSI
  //====================================
  Future<List<TransaksiModel>> getAllTransactions() async {
    try {
      if (uid == null) return [];

      final snapshot = await _db
          .collection('user')
          .doc(uid)
          .collection('transaksi')
          .orderBy('tanggal', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransaksiModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print("Gagal ambil transaksi: $e");
      return [];
    }
  }

  //====================================
  // SALDO SEKARANG
  //====================================
  Future<double> getCurrentSaldo() async {
    try {
      final transaksi = await getAllTransactions();

      double pemasukan = 0;
      double pengeluaran = 0;

      for (var tx in transaksi) {
        if (tx.tipe.toLowerCase().contains("pemasukan")) {
          pemasukan += tx.nominal;
        } else {
          pengeluaran += tx.nominal;
        }
      }

      return pemasukan - pengeluaran;
    } catch (e) {
      print("Gagal hitung saldo: $e");
      return 0;
    }
  }

  //====================================
  // SALDO SAMPAI TANGGAL TERTENTU
  //====================================
  Future<double> getSaldoUntilDate(DateTime targetDate) async {
    try {
      final transaksi = await getAllTransactions();

      double pemasukan = 0;
      double pengeluaran = 0;

      for (var tx in transaksi) {
        if (tx.tanggal.isBefore(targetDate.add(const Duration(days: 1)))) {
          if (tx.tipe.toLowerCase().contains("pemasukan")) {
            pemasukan += tx.nominal;
          } else {
            pengeluaran += tx.nominal;
          }
        }
      }

      return pemasukan - pengeluaran;
    } catch (e) {
      print("Gagal hitung saldo histori: $e");
      return 0;
    }
  }

  //====================================
  // SALDO BERDASARKAN BULAN
  //====================================
  Future<double> getSaldoByMonth(int month, int year) async {
    try {
      final transaksi = await getAllTransactions();

      double pemasukan = 0;
      double pengeluaran = 0;

      for (var tx in transaksi) {
        if (tx.tanggal.month == month && tx.tanggal.year == year) {
          if (tx.tipe.toLowerCase().contains("pemasukan")) {
            pemasukan += tx.nominal;
          } else {
            pengeluaran += tx.nominal;
          }
        }
      }

      return pemasukan - pengeluaran;
    } catch (e) {
      print("Gagal saldo bulanan: $e");
      return 0;
    }
  }

  //====================================
  // TRANSAKSI BERDASARKAN BULAN
  //====================================
  Future<List<TransaksiModel>> getTransactionsByMonth(
    int month,
    int year,
  ) async {
    try {
      final transaksi = await getAllTransactions();

      return transaksi.where((tx) {
        return tx.tanggal.month == month && tx.tanggal.year == year;
      }).toList();
    } catch (e) {
      print("Gagal transaksi bulanan: $e");
      return [];
    }
  }

  Future<void> addCategory(KategoriModel kategori) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .add(kategori.toMap());
  }

  Stream<List<KategoriModel>> getCategoryModels() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KategoriModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> deleteCategory(String id) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('kategori')
        .doc(id)
        .delete();
  }

  // =========================
  // BANK (GANTI BAGIAN LAMA)
  // =========================

  Future<void> addBank(BankModel bank) async {
    if (uid == null) return;

    await _db.collection('user').doc(uid).collection('bank').add(bank.toMap());
  }

  Stream<List<BankModel>> getBankModels() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('bank')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BankModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> deleteBank(String id) async {
    if (uid == null) return;

    await _db.collection('user').doc(uid).collection('bank').doc(id).delete();
  }

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

  // TAGIHAN
  Stream<List<TagihanModels>> getTagihan() {
    if (uid == null) return const Stream.empty();

    return _db
        .collection('user')
        .doc(uid)
        .collection('tagihan')
        .orderBy('tanggalJatuhTempo', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TagihanModels.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addTagihan(TagihanModels tagihan) async {
    if (uid == null) return;
    await _db
        .collection('user')
        .doc(uid)
        .collection('tagihan')
        .add(tagihan.toMap());
  }

  Future<void> executeTagihanPayment(TagihanModels tagihan) async {
    if (uid == null) return;

    try {
      await addTransaction(
        TransaksiModel(
          id: '',
          judul: 'Bayar ${tagihan.judul}',
          kategori: tagihan.kategori,
          bank: tagihan.bank,
          nominal: tagihan.nominal,
          tanggal: DateTime.now(),
          tipe: 'pengeluaran',
        ),
      );

      final originalDate = tagihan.tanggalJatuhTempo;

      final nextMonth = DateTime(
        originalDate.year,
        originalDate.month + 1,
        originalDate.day > 28 ? 28 : originalDate.day,
        originalDate.hour,
        originalDate.minute,
      );

      await _db
          .collection('user')
          .doc(uid)
          .collection('tagihan')
          .doc(tagihan.id)
          .update({'tanggalJatuhTempo': Timestamp.fromDate(nextMonth)});
    } catch (e) {
      print("Error executeTagihanPayment: $e");
      rethrow;
    }
  }

  // HAPUS TAGIHAN MANUAL
  Future<void> deleteTagihan(String tagihanId) async {
    if (uid == null) return;

    await _db
        .collection('user')
        .doc(uid)
        .collection('tagihan')
        .doc(tagihanId)
        .delete();
  }
}
