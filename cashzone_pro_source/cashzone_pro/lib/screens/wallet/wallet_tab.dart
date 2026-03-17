// ============================================================
//  wallet_tab.dart  –  Balance + Withdrawal request + History
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/withdrawal_model.dart';
import '../../services/coin_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});
  @override State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<UserService>().loadWithdrawals()); }

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CoinService>();
    final userService = context.watch<UserService>();
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('👛 My Wallet', style: AppTheme.heading1),
        const SizedBox(height: 20),

        // Balance Card
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF5B21B6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))]),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Coin Balance', style: AppTheme.labelText.copyWith(color: Colors.white70, letterSpacing: 1.5)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('PKR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 36),
              const SizedBox(width: 8),
              Text(coins.formattedCoins, style: AppTheme.coinText.copyWith(fontSize: 40)),
            ]),
            const SizedBox(height: 8),
            Text(coins.formattedPKR, style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _walletStat('Min. Withdrawal', 'PKR 2,500')),
              Expanded(child: _walletStat('Conversion', '500 coins = 1 PKR')),
            ]),
          ])),

        const SizedBox(height: 24),

        // Withdraw button
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton.icon(
          onPressed: coins.pkrBalance >= 2500 ? () => _showWithdrawSheet(context) : null,
          icon: const Icon(Icons.send_rounded),
          label: coins.pkrBalance >= 2500
            ? Text('Withdraw PKR ${coins.pkrBalance.toStringAsFixed(0)}')
            : Text('Need PKR 2,500 to withdraw (have ${coins.pkrBalance.toStringAsFixed(0)})'),
        )).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 24),

        // Withdrawal History
        Text('📋 Withdrawal History', style: AppTheme.heading2),
        const SizedBox(height: 12),
        if (userService.withdrawals.isEmpty)
          Container(padding: const EdgeInsets.all(32), decoration: gradientCard(), child: Center(child: Column(children: [
            const Icon(Icons.history_rounded, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No withdrawals yet', style: AppTheme.bodyText),
          ])))
        else
          ...userService.withdrawals.map((w) => _WithdrawalCard(w).animate().fadeIn()),
      ]))),
    );
  }

  Widget _walletStat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
  ]);

  void _showWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _WithdrawForm(),
    );
  }
}

class _WithdrawForm extends StatefulWidget {
  const _WithdrawForm();
  @override State<_WithdrawForm> createState() => _WithdrawFormState();
}

class _WithdrawFormState extends State<_WithdrawForm> {
  final _accountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.jazzcash;
  bool _loading = false;

  Future<void> _submit() async {
    if (_accountCtrl.text.isEmpty || _titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'))); return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount < 2500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is PKR 2,500'))); return;
    }
    setState(() => _loading = true);
    final err = await context.read<UserService>().submitWithdrawal(
      amountPKR: amount, method: _method,
      accountNumber: _accountCtrl.text, accountTitle: _titleCtrl.text);
    await context.read<CoinService>().loadUserCoins();
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? '✅ Withdrawal submitted! Processing within 24-48h.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Request Withdrawal', style: AppTheme.heading2),
        const SizedBox(height: 20),
        // Payment method
        Text('Payment Method', style: AppTheme.labelText),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: PaymentMethod.values.map((m) => ChoiceChip(
          label: Text('${m.icon} ${m.label}'),
          selected: _method == m, onSelected: (_) => setState(() => _method = m),
          selectedColor: AppTheme.primaryPurple, backgroundColor: AppTheme.bgCardLight,
          labelStyle: TextStyle(color: _method == m ? Colors.white : AppTheme.textSecondary),
        )).toList()),
        const SizedBox(height: 16),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Amount (PKR)', hintText: '2500')),
        const SizedBox(height: 12),
        TextField(controller: _accountCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Account Number / ID')),
        const SizedBox(height: 12),
        TextField(controller: _titleCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(labelText: 'Account Title / Name')),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      ]),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalModel w;
  const _WithdrawalCard(this.w);

  @override
  Widget build(BuildContext context) {
    final statusColor = w.status == WithdrawalStatus.approved ? AppTheme.accentGreen
      : w.status == WithdrawalStatus.rejected ? AppTheme.accentRed : AppTheme.accentGold;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: gradientCard(radius: 16),
      child: Row(children: [
        Text(w.method.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PKR ${w.amountPKR.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          Text('${w.method.label} • ${w.accountNumber}', style: AppTheme.labelText),
          Text(w.requestedAt.toString().substring(0, 10), style: AppTheme.labelText),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.4))),
          child: Text('${w.statusEmoji} ${w.status.name}', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
