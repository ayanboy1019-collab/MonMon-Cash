// ============================================================
//  profile_tab.dart  –  User profile, stats, sign out
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/coin_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final coins = context.watch<CoinService>();
    final user = auth.userModel;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        // Avatar
        Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
          boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 20)]),
          child: user?.photoUrl.isNotEmpty == true
            ? ClipOval(child: Image.network(user!.photoUrl, fit: BoxFit.cover))
            : const Icon(Icons.person_rounded, color: Colors.white, size: 48)),
        const SizedBox(height: 12),
        Text(user?.displayName ?? 'Player', style: AppTheme.heading2),
        Text(user?.email ?? '', style: AppTheme.bodyText),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: neonCard(color: AppTheme.accentGold, radius: 20),
          child: Text('Referral: ${user?.referralCode ?? '...'}',
            style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700))),
        const SizedBox(height: 24),
        // Stats grid
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8,
          children: [
            _stat('Total Coins', coins.formattedCoins, AppTheme.accentGold),
            _stat('Total PKR', coins.formattedPKR, AppTheme.accentGreen),
            _stat('Streak', '${user?.loginStreak ?? 1} days 🔥', AppTheme.accentNeon),
            _stat('Referrals', '${user?.referralCount ?? 0} friends', AppTheme.primaryPurple),
          ]),
        const SizedBox(height: 24),
        // Options
        _option(Icons.notifications_outlined, 'Notifications', () {}),
        _option(Icons.lock_outline, 'Change Password', () {}),
        _option(Icons.help_outline, 'Help & Support', () {}),
        _option(Icons.info_outline, 'About CashZone Pro', () {}),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
          onPressed: () async {
            await auth.signOut();
            if (context.mounted) Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          },
          icon: const Icon(Icons.logout, color: AppTheme.accentRed),
          label: const Text('Sign Out', style: TextStyle(color: AppTheme.accentRed, fontSize: 16)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentRed), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        )),
      ]))),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(16), decoration: neonCard(color: color, radius: 16),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.labelText.copyWith(fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
    ]));

  Widget _option(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: gradientCard(radius: 14),
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondary, size: 22),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500))),
        const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
      ])),
  );
}
