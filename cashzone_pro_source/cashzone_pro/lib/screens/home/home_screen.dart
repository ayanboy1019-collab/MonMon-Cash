// ============================================================
//  home_screen.dart  –  Main shell with bottom nav
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/coin_service.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';
import 'dashboard_tab.dart';
import '../games/games_tab.dart';
import '../earn/earn_tab.dart';
import '../wallet/wallet_tab.dart';
import '../profile/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardTab(),
    GamesTab(),
    EarnTab(),
    WalletTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Load coins & initialise ads on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoinService>().loadUserCoins();
      context.read<AdService>().initializeAds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded),   label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.gamepad_rounded), label: 'Games'),
      BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill_rounded), label: 'Earn'),
      BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallet'),
      BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: items,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
