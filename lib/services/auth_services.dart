import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= REGISTER =================
  Future<String?> register({
    required String email,
    required String password,
    required String nama,
    String? fotoFileName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(nama);

      final uid = userCredential.user?.uid;
      if (uid != null) {
        final data = {'nama': nama};

        if (fotoFileName != null && fotoFileName.isNotEmpty) {
          data['foto'] = fotoFileName;
        }

        await _db
            .collection('user')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "Email sudah digunakan";
        case 'invalid-email':
          return "Format email tidak valid";
        case 'weak-password':
          return "Password terlalu lemah";
        default:
          return e.message;
      }
    } catch (e) {
      print("Register error: $e");
      return "Terjadi kesalahan sistem";
    }
  }

  // ================= LOGIN =================
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "User tidak ditemukan";
        case 'wrong-password':
          return "Password salah";
        case 'invalid-email':
          return "Format email salah";
        default:
          return e.message;
      }
    }
  }

  // ================= UPDATE PROFIL =================
  Future<String?> updateProfile({
    required String newName,
    String? newfotoFileName,
    String? newEmail,
    String? currentPassword, // ✅ FIX DI SINI
  }) async {
    try {
      if (newName.trim().isEmpty) {
        return "Nama tidak boleh kosong";
      }

      User? user = _auth.currentUser;
      if (user == null) return "User tidak ditemukan";

      // Update nama + gender
      await user.updateDisplayName(newName);

      // ================= UPDATE EMAIL =================
      if (newEmail != null &&
          newEmail.trim().isNotEmpty &&
          newEmail != user.email) {
        if (currentPassword == null || currentPassword.isEmpty) {
          return "Masukkan password untuk mengganti email";
        }

        try {
          // ✅ RE-AUTH
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );

          await user.reauthenticateWithCredential(credential);

          // ✅ UPDATE EMAIL (WAJIB VERIFIKASI)
          await user.verifyBeforeUpdateEmail(newEmail);

          return "Cek email baru untuk konfirmasi perubahan";
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password') {
            return "Password salah";
          }
          return e.message;
        }
      }

      // ================= UPDATE FIRESTORE =================
      await _db.collection('users').doc(user.uid).set({
        if (newfotoFileName != null) 'profileImage': newfotoFileName,
      }, SetOptions(merge: true));

      await user.reload();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return "Format email tidak valid";
        case 'email-already-in-use':
          return "Email sudah digunakan";
        case 'network-request-failed':
          return "Tidak ada koneksi internet";
        default:
          return e.message;
      }
    } catch (_) {
      return "Terjadi kesalahan sistem";
    }
  }

  // ================= LOGOUT =================
  Future<void> signOut() async => await _auth.signOut();

  // ================= RESET PASSWORD =================
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Link reset password sudah dikirim";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return "Email tidak terdaftar";
        case 'invalid-email':
          return "Format email salah";
        default:
          return e.message;
      }
    } catch (_) {
      return "Terjadi kesalahan sistem";
    }
  }

  // ================= STREAM USER =================
  Stream<User?> get userChanges => _auth.authStateChanges();
}
