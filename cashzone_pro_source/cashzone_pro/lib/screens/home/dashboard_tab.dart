// ============================================================
//  dashboard_tab.dart  –  Main dashboard with stats & actions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/coin_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';
import '../games/games_tab.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CoinService>();
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────
              _buildHeader(user?.displayName ?? 'Player'),
              const SizedBox(height: 24),

              // ── Balance Card ─────────────────────────
              _buildBalanceCard(coins),
              const SizedBox(height: 20),

              // ── Daily Progress ───────────────────────
              _buildDailyProgress(coins),
              const SizedBox(height: 20),

              // ── Quick Actions ────────────────────────
              Text('Quick Earn', style: AppTheme.heading2),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // ── Stats Row ────────────────────────────
              _buildStatsRow(user),
              const SizedBox(height: 20),

              // ── Leaderboard Preview ──────────────────
              _buildLeaderboardPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👋 Hello, $name!', style: AppTheme.heading2),
            const SizedBox(height: 4),
            Text('Keep earning & cash out!', style: AppTheme.bodyText),
          ],
        ),
        Container(
          width: 48, height: 48,
          decoration: neonCard(color: AppTheme.accentGold, radius: 14),
          child: const Icon(Icons.notifications_outlined,
            color: AppTheme.accentGold, size: 22),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBalanceCard(CoinService coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Balance', style: AppTheme.labelText.copyWith(
                color: Colors.white70, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('PKR', style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 36),
              const SizedBox(width: 8),
              Text(coins.formattedCoins,
                style: AppTheme.coinText.copyWith(fontSize: 40)),
              const SizedBox(width: 8),
              Text('coins', style: AppTheme.bodyText.copyWith(
                color: Colors.white54, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(coins.formattedPKR,
            style: const TextStyle(color: Colors.white70, fontSize: 18,
              fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildDailyProgress(CoinService coins) {
    final progress = coins.dailyLimit > 0
        ? coins.dailyEarned / coins.dailyLimit
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Progress', style: AppTheme.heading2.copyWith(fontSize: 16)),
              Text('${coins.dailyEarned} / ${coins.dailyLimit}',
                style: AppTheme.labelText.copyWith(color: AppTheme.accentNeon)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            coins.canEarnToday
                ? '${coins.remainingToday} coins left today'
                : '🎉 Daily limit reached! Come back tomorrow',
            style: AppTheme.bodyText.copyWith(fontSize: 12),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn();
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.casino_rounded, 'label': 'Daily Spin', 'color': AppTheme.accentGold, 'tab': 2},
      {'icon': Icons.ondemand_video_rounded, 'label': 'Watch Ad', 'color': AppTheme.accentGreen, 'tab': 2},
      {'icon': Icons.gamepad_rounded, 'label': 'Play Game', 'color': AppTheme.primaryPurple, 'tab': 1},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Daily Gift', 'color': AppTheme.accentNeon, 'tab': 2},
    ];

    return Row(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final a = entry.value;
        return Expanded(
          child: GestureDetector(
            onTap: () {/* Navigate to tab */},
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: neonCard(color: a['color'] as Color, radius: 16),
              child: Column(
                children: [
                  Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                  const SizedBox(height: 6),
                  Text(a['label'] as String,
                    style: AppTheme.labelText.copyWith(fontSize: 10),
                    textAlign: TextAlign.center),
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(user) {
    return Row(
      children: [
        _statCard('Total Earned', '${user?.totalEarned ?? 0}', Icons.trending_up),
        const SizedBox(width: 12),
        _statCard('Referrals', '${user?.referralCount ?? 0}', Icons.people_rounded),
        const SizedBox(width: 12),
        _statCard('Streak', '${user?.loginStreak ?? 1} days', Icons.local_fire_department),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: gradientCard(),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentNeon, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.labelText.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    final leaderboard = context.watch<UserService>().leaderboard;
    if (leaderboard.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🏆 Leaderboard', style: AppTheme.heading2),
            TextButton(
              onPressed: () {},
              child: const Text('View All',
                style: TextStyle(color: AppTheme.primaryPurple)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...leaderboard.take(5).toList().asMap().entries.map((e) {
          final rank = e.key + 1;
          final user = e.value;
          final medals = ['🥇', '🥈', '🥉'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: gradientCard(radius: 14),
            child: Row(
              children: [
                Text(rank <= 3 ? medals[rank - 1] : '#$rank',
                  style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(user.displayName,
                  style: const TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600))),
                Row(children: [
                  const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 16),
                  const SizedBox(width: 4),
                  Text('${user.totalEarned}', style: AppTheme.bodyText.copyWith(
                    color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          );
        }),
      ],
    ).animate(delay: 300.ms).fadeIn();
  }
}
