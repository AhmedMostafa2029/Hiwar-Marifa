import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/data/models/user_model.dart';

class Authprovider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // تسجيل مستخدم جديد
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username, // إضافة اسم المستخدم
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          email: email,
          username: username, // حفظ اسم المستخدم
          uid: userCredential.user!.uid,
        );

        // حفظ بيانات المستخدم في Firestore
        await _firestore
            .collection(kUsersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toJson());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;

      // تحديث حالة المستخدم الأخيرة
      await _updateUserLastLogin();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _error = _handleFirebaseError(e);
      throw _error!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // الحصول على بيانات المستخدم الحالي
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection(kUsersCollection)
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!);
      }
    }
    return null;
  }

  Future<void> _updateUserLastLogin() async {
    if (_user != null) {
      await _firestore.collection(kUsersCollection).doc(_user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Login failed: ${e.message}';
    }
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserProfile({
    required String username,
    String? bio,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection(kUsersCollection).doc(user.uid).update({
        'username': username,
        if (bio != null) 'bio': bio,
      });
    }
  }

  // الحصول على اسم المستخدم من الإيميل
  Future<String> getUsernameFromEmail(String email) async {
    try {
      final userQuery = await _firestore
          .collection(kUsersCollection)
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        return userData['username'] ?? email;
      }
      return email;
    } catch (e) {
      return email;
    }
  }

  // الحصول على جميع أسماء المستخدمين
  Future<Map<String, String>> getUsernamesMap(List<String> emails) async {
    final Map<String, String> emailToUsername = {};

    try {
      final usersQuery = await _firestore
          .collection(kUsersCollection)
          .where('email', whereIn: emails)
          .get();

      for (var doc in usersQuery.docs) {
        final userData = doc.data();
        emailToUsername[userData['email']] =
            userData['username'] ?? userData['email'];
      }
    } catch (e) {
      // في حالة الخطأ، نستخدم الإيميلات كأسماء
      for (var email in emails) {
        emailToUsername[email] = email;
      }
    }

    return emailToUsername;
  }
}
