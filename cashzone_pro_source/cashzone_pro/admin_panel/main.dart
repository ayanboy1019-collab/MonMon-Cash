// ============================================================
//  CASHZONE PRO  –  ADMIN PANEL
//  Standalone Flutter Web app. Deploy separately.
//
//  Admin credentials (set in Firebase Auth + Firestore):
//    Email:    Ayanboy1019@gmail.com
//    Password: admin@1122
//    Firestore users/{uid}.isAdmin = true
//
//  Run: cd admin_panel && flutter run -d chrome
//  Deploy: flutter build web && firebase deploy --only hosting
// ============================================================

// admin_panel/lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Entry Point ──────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // Replace with your actual Firebase config
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_PROJECT.firebaseapp.com",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_PROJECT.appspot.com",
      messagingSenderId: "YOUR_SENDER_ID",
      appId: "YOUR_APP_ID",
    ),
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CashZone Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0D0820),
    ),
    home: const AdminLoginPage(),
  );
}

// ─── Admin Login ──────────────────────────────────────────
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController(text: 'Ayanboy1019@gmail.com');
  final _pass  = TextEditingController(text: 'admin@1122');
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(), password: _pass.text);
      // Verify admin flag
      final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      if (doc.data()?['isAdmin'] != true) {
        await FirebaseAuth.instance.signOut();
        setState(() { _error = 'Access denied: not an admin'; _loading = false; });
        return;
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Container(width: 400, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.admin_panel_settings, color: Color(0xFF7C3AED), size: 64),
        const SizedBox(height: 16),
        const Text('CashZone Admin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        TextField(controller: _email, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Email', filled: true, fillColor: Color(0xFF241848))),
        const SizedBox(height: 12),
        TextField(controller: _pass, obscureText: true, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Password', filled: true, fillColor: Color(0xFF241848))),
        if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
          child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Login', style: TextStyle(fontSize: 16)))),
      ])),
    ),
  );
}

// ─── Admin Dashboard Shell ────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _page = 0;
  final _pages = [
    'Overview', 'Users', 'Withdrawals', 'Coin Manager', 'Settings',
  ];
  final _icons = [
    Icons.dashboard, Icons.people, Icons.account_balance_wallet,
    Icons.monetization_on, Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // Sidebar
        Container(width: 220, color: const Color(0xFF1A1035),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('⚙️ Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
            ..._pages.asMap().entries.map((e) => ListTile(
              leading: Icon(_icons[e.key], color: _page == e.key ? const Color(0xFF7C3AED) : Colors.white54),
              title: Text(e.value, style: TextStyle(color: _page == e.key ? const Color(0xFF7C3AED) : Colors.white70,
                fontWeight: _page == e.key ? FontWeight.w700 : FontWeight.normal)),
              selected: _page == e.key,
              selectedTileColor: const Color(0xFF7C3AED).withOpacity(0.1),
              onTap: () => setState(() => _page = e.key),
            )),
            const Spacer(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async { await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())); }),
          ])),
        // Content
        Expanded(child: Scaffold(
          backgroundColor: const Color(0xFF0D0820),
          appBar: AppBar(title: Text(_pages[_page], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            backgroundColor: const Color(0xFF1A1035), elevation: 0),
          body: [
            const _OverviewPage(),
            const _UsersPage(),
            const _WithdrawalsPage(),
            const _CoinManagerPage(),
            const _SettingsPage(),
          ][_page],
        )),
      ]),
    );
  }
}

// ─── Overview Page ────────────────────────────────────────
class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  Future<Map<String, dynamic>> _fetchStats() async {
    final db = FirebaseFirestore.instance;
    final users = await db.collection('users').count().get();
    final pending = await db.collection('withdrawals').where('status', isEqualTo: 'pending').count().get();
    final approved = await db.collection('withdrawals').where('status', isEqualTo: 'approved').count().get();
    return {
      'users': users.count,
      'pending': pending.count,
      'approved': approved.count,
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _fetchStats(),
    builder: (_, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final s = snap.data!;
      return Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Dashboard Overview', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _statCard('Total Users', '${s['users']}', Icons.people, Colors.blue),
          _statCard('Pending Withdrawals', '${s['pending']}', Icons.hourglass_empty, Colors.orange),
          _statCard('Approved Withdrawals', '${s['approved']}', Icons.check_circle, Colors.green),
        ]),
      ]));
    },
  );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
    Container(width: 200, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ]));
}

// ─── Users Page ───────────────────────────────────────────
class _UsersPage extends StatefulWidget {
  const _UsersPage();
  @override State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        controller: _search, onChanged: (v) => setState(() => _query = v.toLowerCase()),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Search users by email...', filled: true, fillColor: Color(0xFF1A1035),
          prefixIcon: Icon(Icons.search, color: Colors.white54)),
      )),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).limit(100).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) {
            if (_query.isEmpty) return true;
            final data = d.data() as Map<String, dynamic>;
            return (data['email'] ?? '').toLowerCase().contains(_query);
          }).toList();
          return DataTable2(docs);
        },
      )),
    ]);
  }
}

class DataTable2 extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const DataTable2(this.docs);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF241848)),
        dataRowColor: WidgetStateProperty.all(const Color(0xFF1A1035)),
        columns: const [
          DataColumn(label: Text('Email', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Name', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Coins', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Status', style: TextStyle(color: Colors.white70))),
          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white70))),
        ],
        rows: docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final isBanned = d['isBanned'] == true;
          return DataRow(cells: [
            DataCell(Text(d['email'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
            DataCell(Text(d['displayName'] ?? '', style: const TextStyle(color: Colors.white70))),
            DataCell(Text('${d['coins'] ?? 0}', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w700))),
            DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: isBanned ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(isBanned ? 'Banned' : 'Active', style: TextStyle(color: isBanned ? Colors.red : Colors.green, fontSize: 12)))),
            DataCell(Row(children: [
              // Add coins
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                onPressed: () => _showAddCoinsDialog(context, doc.id, d['displayName'] ?? '')),
              // Ban/unban
              IconButton(icon: Icon(isBanned ? Icons.lock_open : Icons.block,
                color: isBanned ? Colors.green : Colors.orange, size: 20),
                onPressed: () => FirebaseFirestore.instance.collection('users').doc(doc.id).update({'isBanned': !isBanned})),
            ])),
          ]);
        }).toList(),
      ),
    ),
  );

  void _showAddCoinsDialog(BuildContext context, String uid, String name) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1035),
      title: Text('Adjust Coins: $name', style: const TextStyle(color: Colors.white)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.numberWithOptions(signed: true),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'e.g. 500 or -200', filled: true, fillColor: Color(0xFF241848))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
          onPressed: () async {
            final amount = int.tryParse(ctrl.text);
            if (amount == null) return;
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'coins': FieldValue.increment(amount),
              'totalEarned': amount > 0 ? FieldValue.increment(amount) : FieldValue.increment(0),
            });
            await FirebaseFirestore.instance.collection('coinTransactions').add({
              'userId': uid, 'amount': amount, 'source': 'admin_adjustment',
              'timestamp': FieldValue.serverTimestamp(),
            });
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Apply')),
      ],
    ));
  }
}

// ─── Withdrawals Page ─────────────────────────────────────
class _WithdrawalsPage extends StatefulWidget {
  const _WithdrawalsPage();
  @override State<_WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends State<_WithdrawalsPage> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        ...[('pending','⏳ Pending'), ('approved','✅ Approved'), ('rejected','❌ Rejected')].map((f) =>
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(f.$2), selected: _filter == f.$1,
            onSelected: (_) => setState(() => _filter = f.$1),
            selectedColor: const Color(0xFF7C3AED),
          ))),
      ])),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('withdrawals')
          .where('status', isEqualTo: _filter).orderBy('requestedAt', descending: true).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return Center(child: Text('No $_filter withdrawals', style: const TextStyle(color: Colors.white54)));
          return ListView.builder(padding: const EdgeInsets.all(16),
            itemCount: snap.data!.docs.length,
            itemBuilder: (_, i) {
              final doc = snap.data!.docs[i];
              final d = doc.data() as Map<String, dynamic>;
              return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D2B6B))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('PKR ${d['amountPKR']}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text(d['method'] ?? '', style: const TextStyle(color: Colors.white70)),
                  ]),
                  const SizedBox(height: 8),
                  Text('User: ${d['userEmail']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Account: ${d['accountNumber']} (${d['accountTitle']})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('Coins: ${d['coinsDeducted']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (_filter == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _process(doc.id, 'approved'),
                        child: const Text('✅ Approve'))),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => _processWithNote(context, doc.id, d['userId'], d['coinsDeducted']),
                        child: const Text('❌ Reject'))),
                    ]),
                  ],
                ]));
            });
        },
      )),
    ]);
  }

  Future<void> _process(String docId, String status) async {
    await FirebaseFirestore.instance.collection('withdrawals').doc(docId).update({
      'status': status, 'processedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _processWithNote(BuildContext context, String docId, String userId, int coinsDeducted) async {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1035),
      title: const Text('Rejection Reason', style: TextStyle(color: Colors.white)),
      content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'Optional note...', filled: true, fillColor: Color(0xFF241848))),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            // Reject: refund coins to user
            await FirebaseFirestore.instance.collection('withdrawals').doc(docId).update({
              'status': 'rejected', 'processedAt': FieldValue.serverTimestamp(), 'adminNote': ctrl.text,
            });
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'coins': FieldValue.increment(coinsDeducted),
            });
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Reject & Refund Coins')),
      ],
    ));
  }
}

// ─── Coin Manager ─────────────────────────────────────────
class _CoinManagerPage extends StatefulWidget {
  const _CoinManagerPage();
  @override State<_CoinManagerPage> createState() => _CoinManagerPageState();
}

class _CoinManagerPageState extends State<_CoinManagerPage> {
  final _limitCtrl = TextEditingController(text: '10000');
  final _refCtrl = TextEditingController(text: '500');

  Future<void> _updateGlobalSettings() async {
    final limit = int.tryParse(_limitCtrl.text);
    final refBonus = int.tryParse(_refCtrl.text);
    if (limit == null || refBonus == null) return;
    await FirebaseFirestore.instance.collection('config').doc('global').set({
      'dailyLimit': limit, 'referralBonus': refBonus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
  }

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Global Coin Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Daily Earning Limit (per user)', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(controller: _limitCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(filled: true, fillColor: Color(0xFF241848))),
        const SizedBox(height: 16),
        const Text('Referral Bonus Coins', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(controller: _refCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(filled: true, fillColor: Color(0xFF241848))),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
          onPressed: _updateGlobalSettings,
          child: const Text('Save Settings', style: TextStyle(fontSize: 16))),
      ])),
    ]));
}

// ─── Settings Page ────────────────────────────────────────
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('App Settings', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
    const SizedBox(height: 20),
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _settingRow('Minimum Withdrawal', 'PKR 2,500'),
      _settingRow('Coin Rate', '500 coins = 1 PKR'),
      _settingRow('Daily Limit', '10,000 coins'),
      _settingRow('Referrer Bonus', '500 coins'),
      _settingRow('New User Bonus', '200 coins (with referral)'),
      _settingRow('Base Welcome Coins', '100 coins'),
    ])),
    const SizedBox(height: 24),
    const Text('Ad Network Config', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1A1035), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.orange.withOpacity(0.3))), child: const Text(
      '⚠️  Replace test ad unit IDs in AdService:\n'
      '  • Interstitial: ca-app-pub-XXXX/XXXX\n'
      '  • Rewarded:     ca-app-pub-XXXX/XXXX\n'
      '  • Banner:       ca-app-pub-XXXX/XXXX\n\n'
      'For AppLovin MAX, add applovin_max package\n'
      'and call AppLovinMAX.initialize(sdk_key).',
      style: TextStyle(color: Colors.orange, fontFamily: 'monospace', fontSize: 13))),
  ]));

  Widget _settingRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
      Text(value, style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w700)),
    ]));
}
