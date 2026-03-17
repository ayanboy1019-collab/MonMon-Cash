// ============================================================
//  user_model.dart  –  CashZone Pro user data model
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int coins;
  final int totalEarned;        // lifetime total coins earned
  final int dailyEarned;        // coins earned today (resets midnight)
  final int dailyLimit;         // default 10000, admin can change
  final String referralCode;    // unique 8-char code
  final String? referredBy;     // uid of referrer
  final int referralCount;      // how many users this user referred
  final int referralEarnings;   // coins earned from referrals
  final bool isBanned;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int loginStreak;        // consecutive login days
  final DateTime? lastDailyReward;
  final DateTime? lastFreeSpin;
  final String? withdrawalAccountType; // jazzcash, easypaisa, bank, etc.
  final String? withdrawalAccountNumber;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.coins,
    required this.totalEarned,
    required this.dailyEarned,
    required this.dailyLimit,
    required this.referralCode,
    this.referredBy,
    required this.referralCount,
    required this.referralEarnings,
    required this.isBanned,
    required this.isAdmin,
    required this.createdAt,
    required this.lastLoginAt,
    required this.loginStreak,
    this.lastDailyReward,
    this.lastFreeSpin,
    this.withdrawalAccountType,
    this.withdrawalAccountNumber,
  });

  // ── Convert Firestore doc → UserModel ─────────────────
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Player',
      photoUrl: data['photoUrl'] ?? '',
      coins: (data['coins'] ?? 0).toInt(),
      totalEarned: (data['totalEarned'] ?? 0).toInt(),
      dailyEarned: (data['dailyEarned'] ?? 0).toInt(),
      dailyLimit: (data['dailyLimit'] ?? 10000).toInt(),
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      referralCount: (data['referralCount'] ?? 0).toInt(),
      referralEarnings: (data['referralEarnings'] ?? 0).toInt(),
      isBanned: data['isBanned'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      loginStreak: (data['loginStreak'] ?? 1).toInt(),
      lastDailyReward: (data['lastDailyReward'] as Timestamp?)?.toDate(),
      lastFreeSpin: (data['lastFreeSpin'] as Timestamp?)?.toDate(),
      withdrawalAccountType: data['withdrawalAccountType'],
      withdrawalAccountNumber: data['withdrawalAccountNumber'],
    );
  }

  // ── Convert UserModel → Firestore Map ─────────────────
  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'coins': coins,
    'totalEarned': totalEarned,
    'dailyEarned': dailyEarned,
    'dailyLimit': dailyLimit,
    'referralCode': referralCode,
    'referredBy': referredBy,
    'referralCount': referralCount,
    'referralEarnings': referralEarnings,
    'isBanned': isBanned,
    'isAdmin': isAdmin,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    'loginStreak': loginStreak,
    'lastDailyReward': lastDailyReward != null
        ? Timestamp.fromDate(lastDailyReward!)
        : null,
    'lastFreeSpin': lastFreeSpin != null
        ? Timestamp.fromDate(lastFreeSpin!)
        : null,
    'withdrawalAccountType': withdrawalAccountType,
    'withdrawalAccountNumber': withdrawalAccountNumber,
  };

  // ── Computed helpers ───────────────────────────────────
  double get pkrBalance => coins / 500.0;   // 500 coins = 1 PKR
  bool get canWithdraw => pkrBalance >= 2500;
  int get remainingDailyCoins => dailyLimit - dailyEarned;
  bool get canEarnToday => dailyEarned < dailyLimit;

  bool get canClaimDailyReward {
    if (lastDailyReward == null) return true;
    final now = DateTime.now();
    final last = lastDailyReward!;
    return now.year != last.year ||
           now.month != last.month ||
           now.day != last.day;
  }

  bool get canFreeSpin {
    if (lastFreeSpin == null) return true;
    return DateTime.now().difference(lastFreeSpin!).inHours >= 24;
  }

  // Daily reward amount increases with streak (capped at 30 days)
  int get dailyRewardCoins {
    const base = 50;
    const perDay = 25;
    const maxDays = 30;
    final streak = loginStreak.clamp(1, maxDays);
    return base + (streak - 1) * perDay;
  }

  UserModel copyWith({
    int? coins,
    int? totalEarned,
    int? dailyEarned,
    int? loginStreak,
    DateTime? lastDailyReward,
    DateTime? lastFreeSpin,
    int? referralCount,
    int? referralEarnings,
    bool? isBanned,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      coins: coins ?? this.coins,
      totalEarned: totalEarned ?? this.totalEarned,
      dailyEarned: dailyEarned ?? this.dailyEarned,
      dailyLimit: dailyLimit,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      isBanned: isBanned ?? this.isBanned,
      isAdmin: isAdmin,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      loginStreak: loginStreak ?? this.loginStreak,
      lastDailyReward: lastDailyReward ?? this.lastDailyReward,
      lastFreeSpin: lastFreeSpin ?? this.lastFreeSpin,
      withdrawalAccountType: withdrawalAccountType,
      withdrawalAccountNumber: withdrawalAccountNumber,
    );
  }
}
