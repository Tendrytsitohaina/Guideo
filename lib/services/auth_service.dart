import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Impossible de créer le compte.',
      );
    }

    await user.updateDisplayName(name.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': user.email,
      'notificationsEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<void> updateProfile({
    required String name,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await user.updateDisplayName(name.trim());
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotifications(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'notificationsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> notificationsEnabled() async {
    final user = _auth.currentUser;
    if (user == null) {
      return true;
    }

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data()?['notificationsEnabled'] as bool? ?? true;
  }

  Future<void> signOut() => _auth.signOut();
}
