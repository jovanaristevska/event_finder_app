import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> signUp(String email, String password, String fullName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Создади корисник
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 2. Постави го името (displayName)
      await credential.user?.updateDisplayName(fullName.trim());
      await credential.user?.reload(); // освежи го локалниот корисник

      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapError(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    return _runAuth(() => _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    ));
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<bool> _runAuth(Future<UserCredential> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapError(e.code);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'weak-password':
        return 'Лозинката е премногу слаба (мин. 6 знаци).';
      case 'email-already-in-use':
        return 'Веќе постои корисник со овој email.';
      case 'invalid-email':
        return 'Невалиден email формат.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Погрешен email или лозинка.';
      default:
        return 'Се случи грешка. Обиди се повторно.';
    }
  }
}