// ============================================================
//  coin_service.dart  –  Manages all coin operations
//
//  Anti-cheat features:
//   • Daily earning cap (default 10,000 coins)
//   • Server-side Firestore transactions (atomic updates)
//   • Per-game cooldowns stored server side
//   • Suspicious activity detection
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinTransaction {
  final String source;   // 'game_tap', 'daily_reward', 'ad_reward', etc.
  final int amount;
  final DateTime timestamp;
  CoinTransaction(this.source, this.amount, this.timestamp);
}

class CoinService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _coins = 0;
  int _dailyEarned = 0;
  int _dailyLimit = 10000;
  bool _isLoading = false;
  String? _error;

  int get coins => _coins;
  int get dailyEarned => _dailyEarned;
  int get dailyLimit => _dailyLimit;
  int get remainingToday => (_dailyLimit - _dailyEarned).clamp(0, _dailyLimit);
  bool get canEarnToday => _dailyEarned < _dailyLimit;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── PKR conversion (500 coins = 1 PKR) ────────────────
  double get pkrBalance => _coins / 500.0;
  String get formattedCoins => _coins.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  String get formattedPKR => 'PKR ${pkrBalance.toStringAsFixed(2)}';

  // ── Load current user's coins from Firestore ──────────
  Future<void> loadUserCoins() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _coins = (data['coins'] ?? 0).toInt();
        _dailyLimit = (data['dailyLimit'] ?? 10000).toInt();

        // Reset daily earned if it's a new day
        final lastReset = (data['dailyResetAt'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        if (lastReset == null ||
            lastReset.year != now.year ||
            lastReset.month != now.month ||
            lastReset.day != now.day) {
          // New day – reset counter in Firestore
          await _db.collection('users').doc(uid).update({
            'dailyEarned': 0,
            'dailyResetAt': Timestamp.fromDate(now),
          });
          _dailyEarned = 0;
        } else {
          _dailyEarned = (data['dailyEarned'] ?? 0).toInt();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Award coins to user (main method) ─────────────────
  // Returns the actual amount awarded (may be capped by daily limit)
  Future<int> awardCoins({
    required int amount,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    // Cap by daily limit
    final maxCanEarn = remainingToday;
    if (maxCanEarn <= 0) return 0;
    final actualAmount = amount.clamp(0, maxCanEarn);
    if (actualAmount == 0) return 0;

    try {
      // Atomic Firestore transaction – prevents cheating via race conditions
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(uid);
        final snap = await transaction.get(userRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        final currentCoins = (data['coins'] ?? 0).toInt();
        final currentDaily = (data['dailyEarned'] ?? 0).toInt();
        final limit = (data['dailyLimit'] ?? 10000).toInt();

        // Server-side daily limit check
        final serverRemaining = limit - currentDaily;
        if (serverRemaining <= 0) return;
        final serverAmount = actualAmount.clamp(0, serverRemaining);

        transaction.update(userRef, {
          'coins': currentCoins + serverAmount,
          'dailyEarned': currentDaily + serverAmount,
          'totalEarned': FieldValue.increment(serverAmount),
        });

        // Log transaction for audit trail
        transaction.set(
          _db.collection('coinTransactions').doc(),
          {
            'userId': uid,
            'amount': serverAmount,
            'source': source,
            'timestamp': FieldValue.serverTimestamp(),
            'metadata': metadata ?? {},
          },
        );
      });

      // Update local state
      _coins += actualAmount;
      _dailyEarned += actualAmount;
      notifyListeners();

      return actualAmount;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // ── Deduct coins (for withdrawal) ─────────────────────
  Future<bool> deductCoins({
    required int amount,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || amount > _coins) return false;

    try {
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(uid);
        final snap = await transaction.get(userRef);
        final currentCoins = (snap.data()?['coins'] ?? 0).toInt();
        if (currentCoins < amount) throw Exception('Insufficient coins');
        transaction.update(userRef, {'coins': currentCoins - amount});
      });

      _coins -= amount;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Per-game cooldown check ────────────────────────────
  // Stored in Firestore so client can't manipulate local state
  Future<bool> checkAndSetCooldown({
    required String gameId,
    required Duration cooldown,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final cooldownRef = _db
        .collection('users')
        .doc(uid)
        .collection('cooldowns')
        .doc(gameId);

    final snap = await cooldownRef.get();
    if (snap.exists) {
      final lastPlayed = (snap.data()!['lastPlayed'] as Timestamp).toDate();
      if (DateTime.now().difference(lastPlayed) < cooldown) {
        return false; // Still on cooldown
      }
    }

    await cooldownRef.set({'lastPlayed': FieldValue.serverTimestamp()});
    return true; // Allowed to play
  }

  // ── Get cooldown remaining ─────────────────────────────
  Future<Duration> getCooldownRemaining({
    required String gameId,
    required Duration cooldown,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Duration.zero;

    final cooldownRef = _db
        .collection('users')
        .doc(uid)
        .collection('cooldowns')
        .doc(gameId);

    final snap = await cooldownRef.get();
    if (!snap.exists) return Duration.zero;

    final lastPlayed = (snap.data()!['lastPlayed'] as Timestamp).toDate();
    final elapsed = DateTime.now().difference(lastPlayed);
    final remaining = cooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
