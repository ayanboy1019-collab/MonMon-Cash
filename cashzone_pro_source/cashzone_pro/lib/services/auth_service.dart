// ============================================================
//  auth_service.dart  –  Firebase Auth + Google Sign-in
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:math';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // ── Referral code coins ───────────────────────────────
  static const int referrerBonus = 500;      // coins for the person who referred
  static const int newUserReferralBonus = 200; // coins for new user who used a code

  // ── Email & Password Sign Up ──────────────────────────
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      await _createUserDocument(
        uid: cred.user!.uid,
        email: email,
        displayName: displayName,
        referralCode: referralCode,
      );
      await _loadUserModel(cred.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Email & Password Login ────────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      await _loadUserModel(cred.user!.uid);
      await _updateLoginStreak(cred.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e.code);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Google Sign-in ────────────────────────────────────
  Future<bool> signInWithGoogle({String? referralCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final isNew = cred.additionalUserInfo?.isNewUser ?? false;

      if (isNew) {
        await _createUserDocument(
          uid: cred.user!.uid,
          email: cred.user!.email!,
          displayName: cred.user!.displayName ?? 'Player',
          photoUrl: cred.user!.photoURL,
          referralCode: referralCode,
        );
      }

      await _loadUserModel(cred.user!.uid);
      await _updateLoginStreak(cred.user!.uid);
      return true;
    } catch (e) {
      _error = 'Google Sign-in failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Forgot Password ───────────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authErrorMessage(e.code);
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // ── Create Firestore user document ────────────────────
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    String? referralCode,
  }) async {
    final uniqueCode = _generateReferralCode(uid);
    final now = DateTime.now();

    // Check if referral code is valid
    String? referrerUid;
    if (referralCode != null && referralCode.isNotEmpty) {
      final query = await _db
          .collection('users')
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        referrerUid = query.docs.first.id;
      }
    }

    // Create the new user document
    await _db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl ?? '',
      'coins': referrerUid != null ? newUserReferralBonus : 100, // welcome bonus
      'totalEarned': referrerUid != null ? newUserReferralBonus : 100,
      'dailyEarned': 0,
      'dailyLimit': 10000,
      'referralCode': uniqueCode,
      'referredBy': referrerUid,
      'referralCount': 0,
      'referralEarnings': 0,
      'isBanned': false,
      'isAdmin': false,
      'createdAt': Timestamp.fromDate(now),
      'lastLoginAt': Timestamp.fromDate(now),
      'loginStreak': 1,
      'dailyResetAt': Timestamp.fromDate(now),
    });

    // Reward the referrer
    if (referrerUid != null) {
      await _db.collection('users').doc(referrerUid).update({
        'coins': FieldValue.increment(referrerBonus),
        'referralCount': FieldValue.increment(1),
        'referralEarnings': FieldValue.increment(referrerBonus),
        'totalEarned': FieldValue.increment(referrerBonus),
      });
    }
  }

  // ── Update login streak ───────────────────────────────
  Future<void> _updateLoginStreak(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data()!;
    final lastLogin = (data['lastLoginAt'] as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(lastLogin).inDays;
    int streak = (data['loginStreak'] ?? 1).toInt();

    if (diff == 1) {
      streak++; // consecutive day
    } else if (diff > 1) {
      streak = 1; // streak broken
    }

    await _db.collection('users').doc(uid).update({
      'lastLoginAt': Timestamp.fromDate(now),
      'loginStreak': streak,
    });
  }

  // ── Load user model into memory ───────────────────────
  Future<void> _loadUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      _userModel = UserModel.fromFirestore(doc);
      notifyListeners();
    }
  }

  // ── Generate unique referral code ─────────────────────
  String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    // Take 4 chars from UID prefix + 4 random
    final prefix = uid.substring(0, 4).toUpperCase();
    final suffix = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$prefix$suffix';
  }

  // ── Human-readable auth errors ────────────────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email.';
      case 'wrong-password':       return 'Incorrect password. Please try again.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password':        return 'Password must be at least 6 characters.';
      case 'invalid-email':        return 'Please enter a valid email address.';
      case 'too-many-requests':    return 'Too many attempts. Please wait a moment.';
      case 'network-request-failed': return 'No internet connection.';
      default:                     return 'Authentication failed. Please try again.';
    }
  }
}
