// ============================================================
//  earn_tab.dart  –  Watch Ads, Daily Reward, Free Spin
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../services/coin_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';

class EarnTab extends StatefulWidget {
  const EarnTab({super.key});
  @override State<EarnTab> createState() => _EarnTabState();
}

class _EarnTabState extends State<EarnTab> {
  late ConfettiController _confetti;
  bool _claimingDaily = false, _claimingSpin = false, _watchingAd = false;

  @override void initState() { super.initState(); _confetti = ConfettiController(duration: const Duration(seconds: 2)); }
  @override void dispose() { _confetti.dispose(); super.dispose(); }

  Future<void> _claimDaily() async {
    setState(() => _claimingDaily = true);
    final awarded = await context.read<UserService>().claimDailyReward();
    if (awarded > 0) {
      await context.read<CoinService>().loadUserCoins();
      _confetti.play();
      _showCoinDialog('Daily Reward', awarded, '🎁');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already claimed today! Come back tomorrow.')));
    }
    setState(() => _claimingDaily = false);
  }

  Future<void> _freeSpin() async {
    setState(() => _claimingSpin = true);
    final awarded = await context.read<UserService>().claimFreeSpin();
    if (awarded > 0) {
      await context.read<CoinService>().loadUserCoins();
      _confetti.play();
      _showCoinDialog('Free Spin', awarded, '🎰');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⏳ Free spin available every 24 hours!')));
    }
    setState(() => _claimingSpin = false);
  }

  Future<void> _watchAd() async {
    setState(() => _watchingAd = true);
    await context.read<AdService>().showRewardedAd(
      rewardCoins: 100,
      onReward: (coins) async {
        final awarded = await context.read<CoinService>().awardCoins(amount: coins, source: 'watch_ad');
        _confetti.play();
        if (mounted) _showCoinDialog('Ad Reward', awarded, '📺');
      },
      onFailure: () {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready. Please try again.')));
      },
    );
    setState(() => _watchingAd = false);
  }

  void _showCoinDialog(String title, int coins, String emoji) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 12),
        Text(title, style: AppTheme.heading2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('+$coins Coins', style: AppTheme.coinText),
      ]),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Great!'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Stack(children: [
          Align(alignment: Alignment.topCenter, child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive)),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💰 Earn Coins', style: AppTheme.heading1),
              const SizedBox(height: 4),
              Text('Multiple ways to earn every day', style: AppTheme.bodyText),
              const SizedBox(height: 24),

              // ── Watch Ads ──────────────────────────
              _earnCard(
                emoji: '📺', title: 'Watch Ad', subtitle: 'Earn 100 coins per video',
                coinReward: 100, color: AppTheme.accentGreen,
                isLoading: _watchingAd,
                buttonLabel: 'Watch Now',
                onTap: _watchAd,
              ).animate().fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 16),

              // ── Daily Reward ───────────────────────
              _earnCard(
                emoji: '🎁', title: 'Daily Reward', subtitle: 'Increases with your login streak',
                coinReward: null, color: AppTheme.primaryPurple,
                isLoading: _claimingDaily,
                buttonLabel: 'Claim Reward',
                onTap: _claimDaily,
              ).animate(delay: 80.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 16),

              // ── Free Spin ──────────────────────────
              _earnCard(
                emoji: '🎰', title: 'Free Daily Spin', subtitle: 'Win 50–500 coins every 24h',
                coinReward: null, color: AppTheme.accentGold,
                isLoading: _claimingSpin,
                buttonLabel: 'Spin Now',
                onTap: _freeSpin,
              ).animate(delay: 160.ms).fadeIn().slideX(begin: -0.05),

              const SizedBox(height: 24),

              // ── Referral Section ───────────────────
              Text('👥 Refer & Earn', style: AppTheme.heading2),
              const SizedBox(height: 12),
              _ReferralSection().animate(delay: 240.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Coin Rate Info ─────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: gradientCard(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('💱 Conversion Rate', style: AppTheme.heading2.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  _rateRow('500 coins', '= 1 PKR'),
                  _rateRow('1,250,000 coins', '= PKR 2,500 (min. withdrawal)'),
                  _rateRow('Daily limit', '10,000 coins'),
                ]),
              ).animate(delay: 300.ms).fadeIn(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _earnCard({required String emoji, required String title, required String subtitle,
    required int? coinReward, required Color color, required bool isLoading,
    required String buttonLabel, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: neonCard(color: color),
      child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.4))),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(subtitle, style: AppTheme.labelText),
          if (coinReward != null) ...[const SizedBox(height: 4), Text('+$coinReward 🪙', style: TextStyle(color: color, fontWeight: FontWeight.w700))],
        ])),
        ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(buttonLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _rateRow(String left, String right) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Expanded(child: Text(left, style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w600))),
      Text(right, style: AppTheme.bodyText),
    ]),
  );
}

class _ReferralSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: neonCard(color: AppTheme.accentNeon),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📩 Your Referral Code', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          Text('+500 coins per invite', style: AppTheme.labelText.copyWith(color: AppTheme.accentGreen)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(color: AppTheme.bgDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accentNeon.withOpacity(0.4))),
          child: Row(children: [
            const Icon(Icons.tag, color: AppTheme.accentNeon, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('CZPRO1234', style: TextStyle(color: AppTheme.accentNeon, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3))),
            IconButton(icon: const Icon(Icons.copy, color: AppTheme.textMuted, size: 20), onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
            }),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share & Invite Friends'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentNeon, side: const BorderSide(color: AppTheme.accentNeon)),
        )),
      ]),
    );
  }
}
