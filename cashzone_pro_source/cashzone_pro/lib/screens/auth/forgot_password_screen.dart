// forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final auth = context.read<AuthService>();
    final ok = await auth.sendPasswordResetEmail(_emailCtrl.text.trim());
    if (ok) setState(() => _sent = true);
    else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Failed')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient), child: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
      const SizedBox(height: 24),
      Text('Reset Password', style: AppTheme.heading1),
      const SizedBox(height: 8),
      Text('Enter your email and we\'ll send a reset link.', style: AppTheme.bodyText),
      const SizedBox(height: 32),
      if (!_sent) ...[
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'your@email.com', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _send, child: const Text('Send Reset Link', style: TextStyle(fontSize: 16)))),
      ] else ...[
        Container(padding: const EdgeInsets.all(24), decoration: neonCard(color: AppTheme.accentGreen), child: Column(children: [
          const Icon(Icons.mark_email_read_outlined, color: AppTheme.accentGreen, size: 64),
          const SizedBox(height: 16),
          Text('Email Sent!', style: AppTheme.heading2.copyWith(color: AppTheme.accentGreen)),
          const SizedBox(height: 8),
          const Text('Check your inbox and follow the link to reset your password.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
        ])),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login'))),
      ],
    ])))),
  );
}
