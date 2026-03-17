// ============================================================
//  user_service.dart  –  Withdrawals, referrals, leaderboard
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/withdrawal_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<WithdrawalModel> _withdrawals = [];
  List<UserModel> _leaderboard = [];
  bool _isLoading = false;

  List<WithdrawalModel> get withdrawals => _withdrawals;
  List<UserModel> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;

  // ── Submit withdrawal request ─────────────────────────
  Future<String?> submitWithdrawal({
    required double amountPKR,
    required PaymentMethod method,
    required String accountNumber,
    required String accountTitle,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Not logged in';

    if (amountPKR < 2500) return 'Minimum withdrawal is PKR 2,500';

    final coinsRequired = (amountPKR * 500).toInt();

    // Check user has enough coins
    final userDoc = await _db.collection('users').doc(uid).get();
    final currentCoins = (userDoc.data()?['coins'] ?? 0).toInt();
    if (currentCoins < coinsRequired) return 'Insufficient coins';

    try {
      // Use transaction: deduct coins + create withdrawal request atomically
      await _db.runTransaction((txn) async {
        final userRef = _db.collection('users').doc(uid);
        final snap = await txn.get(userRef);
        final coins = (snap.data()?['coins'] ?? 0).toInt();
        if (coins < coinsRequired) throw Exception('Insufficient coins');

        txn.update(userRef, {'coins': coins - coinsRequired});

        txn.set(_db.collection('withdrawals').doc(), {
          'userId': uid,
          'userEmail': _auth.currentUser!.email,
          'amountPKR': amountPKR,
          'coinsDeducted': coinsRequired,
          'method': method.name,
          'accountNumber': accountNumber,
          'accountTitle': accountTitle,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
          'processedAt': null,
          'adminNote': null,
        });
      });

      await loadWithdrawals();
      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Load user's withdrawal history ────────────────────
  Future<void> loadWithdrawals() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final query = await _db
        .collection('withdrawals')
        .where('userId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .limit(20)
        .get();

    _withdrawals = query.docs
        .map((doc) => WithdrawalModel.fromFirestore(doc))
        .toList();
    notifyListeners();
  }

  // ── Load top 50 leaderboard ───────────────────────────
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    final query = await _db
        .collection('users')
        .orderBy('totalEarned', descending: true)
        .limit(50)
        .get();

    _leaderboard = query.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  // ── Update payment account details ────────────────────
  Future<void> updatePaymentDetails({
    required String accountType,
    required String accountNumber,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'withdrawalAccountType': accountType,
      'withdrawalAccountNumber': accountNumber,
    });
  }

  // ── Claim daily reward ────────────────────────────────
  // Returns coins awarded, or 0 if already claimed today
  Future<int> claimDailyReward() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final userRef = _db.collection('users').doc(uid);

    try {
      int awarded = 0;
      await _db.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        final data = snap.data()!;
        final lastClaim = (data['lastDailyReward'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        // Check if already claimed today
        if (lastClaim != null &&
            lastClaim.year == now.year &&
            lastClaim.month == now.month &&
            lastClaim.day == now.day) {
          awarded = 0;
          return;
        }

        final streak = (data['loginStreak'] ?? 1).toInt();
        final rewardCoins = 50 + (streak.clamp(1, 30) - 1) * 25;
        final currentCoins = (data['coins'] ?? 0).toInt();
        final dailyEarned = (data['dailyEarned'] ?? 0).toInt();
        final dailyLimit = (data['dailyLimit'] ?? 10000).toInt();
        final canEarn = (dailyLimit - dailyEarned).clamp(0, rewardCoins);

        txn.update(userRef, {
          'coins': currentCoins + canEarn,
          'dailyEarned': dailyEarned + canEarn,
          'totalEarned': FieldValue.increment(canEarn),
          'lastDailyReward': FieldValue.serverTimestamp(),
        });

        awarded = canEarn;
      });

      return awarded;
    } catch (e) {
      return 0;
    }
  }

  // ── Daily free spin result ────────────────────────────
  Future<int> claimFreeSpin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final userRef = _db.collection('users').doc(uid);

    try {
      int awarded = 0;
      await _db.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        final data = snap.data()!;
        final lastSpin = (data['lastFreeSpin'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (lastSpin != null && now.difference(lastSpin).inHours < 24) {
          awarded = 0;
          return;
        }

        // Random reward 50-500 coins
        final rewards = [50, 100, 150, 200, 300, 500];
        rewards.shuffle();
        final prize = rewards.first;

        final currentCoins = (data['coins'] ?? 0).toInt();
        final dailyEarned = (data['dailyEarned'] ?? 0).toInt();
        final dailyLimit = (data['dailyLimit'] ?? 10000).toInt();
        final canEarn = (dailyLimit - dailyEarned).clamp(0, prize);

        txn.update(userRef, {
          'coins': currentCoins + canEarn,
          'dailyEarned': dailyEarned + canEarn,
          'totalEarned': FieldValue.increment(canEarn),
          'lastFreeSpin': FieldValue.serverTimestamp(),
        });

        awarded = canEarn;
      });

      return awarded;
    } catch (e) {
      return 0;
    }
  }
}
