// signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _refCtrl.dispose(); super.dispose(); }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.signUpWithEmail(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(), referralCode: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim());
    if (!mounted) return;
    if (ok) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Sign up failed')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(body: Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        Center(child: Column(children: [
          Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
            child: const Icon(Icons.monetization_on_rounded, size: 36, color: AppTheme.accentGold)),
          const SizedBox(height: 12),
          Text('Create Account', style: AppTheme.heading1),
          Text('Start earning today!', style: AppTheme.bodyText),
        ])),
        const SizedBox(height: 32),
        Text('Full Name', style: AppTheme.labelText), const SizedBox(height: 8),
        TextFormField(controller: _nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted)),
          validator: (v) => v!.length >= 2 ? null : 'Name too short'),
        const SizedBox(height: 16),
        Text('Email', style: AppTheme.labelText), const SizedBox(height: 8),
        TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'your@email.com', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted)),
          validator: (v) => v!.contains('@') ? null : 'Enter valid email'),
        const SizedBox(height: 16),
        Text('Password', style: AppTheme.labelText), const SizedBox(height: 8),
        TextFormField(controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(hintText: '••••••••', prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted), onPressed: () => setState(() => _obscure = !_obscure))),
          validator: (v) => v!.length >= 6 ? null : 'Min 6 characters'),
        const SizedBox(height: 16),
        Text('Referral Code (optional)', style: AppTheme.labelText), const SizedBox(height: 8),
        TextFormField(controller: _refCtrl, style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Enter referral code for bonus coins', prefixIcon: Icon(Icons.card_giftcard, color: AppTheme.textMuted))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: auth.isLoading ? null : _signUp,
          child: auth.isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 16),
        Center(child: GestureDetector(onTap: () => Navigator.pop(context),
          child: const Text('Already have an account? Sign In', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w600)))),
      ]))))));
  }
}
