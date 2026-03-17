// ============================================================
//  login_screen.dart  –  Email/Password + Google login
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final success = await auth.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
    }
  }

  Future<void> _googleLogin() async {
    final auth = context.read<AuthService>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // ── Header ────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
                            ),
                            boxShadow: [BoxShadow(
                              color: AppTheme.primaryPurple.withOpacity(0.4),
                              blurRadius: 20,
                            )],
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            size: 42, color: AppTheme.accentGold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Welcome Back!', style: AppTheme.heading1),
                        const SizedBox(height: 6),
                        Text('Sign in to continue earning', style: AppTheme.bodyText),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                  const SizedBox(height: 40),

                  // ── Email Field ───────────────────────
                  Text('Email', style: AppTheme.labelText),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'your@email.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    ),
                    validator: (v) => v!.contains('@') ? null : 'Enter valid email',
                  ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.05),

                  const SizedBox(height: 16),

                  // ── Password Field ────────────────────
                  Text('Password', style: AppTheme.labelText),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v!.length >= 6 ? null : 'Password too short',
                  ).animate(delay: 150.ms).fadeIn().slideX(begin: -0.05),

                  // ── Forgot Password ───────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot Password?',
                        style: TextStyle(color: AppTheme.primaryPurple)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Login Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ── Divider ───────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppTheme.bodyText),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderColor)),
                  ]),

                  const SizedBox(height: 20),

                  // ── Google Sign-in ────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _googleLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      icon: const Text('G', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      )),
                      label: const Text('Continue with Google',
                        style: TextStyle(fontSize: 16)),
                    ),
                  ).animate(delay: 250.ms).fadeIn(),

                  const SizedBox(height: 32),

                  // ── Sign Up Link ──────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: "Don't have an account? ",
                            style: TextStyle(color: AppTheme.textSecondary)),
                          TextSpan(text: 'Sign Up',
                            style: TextStyle(color: AppTheme.primaryPurple,
                              fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
