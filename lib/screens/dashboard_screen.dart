import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_theme.dart';
import 'login_screen.dart';
import 'admin_screen.dart';
import 'customer_screen.dart';
import 'labour_screen.dart';
import 'reports_screen.dart';
import 'dead_chicks_screen.dart';
import 'medicine_screen.dart';
import 'feed_screen.dart';
import 'quick_update_screen.dart';
import 'transaction_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<Offset>> _cardAnims;

  final List<_MenuCard> _menuItems = [
    _MenuCard(title: 'Admin Panel', subtitle: 'Income, Expenses & Farm Data', icon: Icons.admin_panel_settings_rounded, color: AppTheme.primaryDark),
    _MenuCard(title: 'Manage Customers', subtitle: 'Customer records & transactions', icon: Icons.people_alt_rounded, color: Color(0xFF1565C0)),
    _MenuCard(title: 'Quick Customer Update', subtitle: 'Search & update returning customers', icon: Icons.update_rounded, color: Color(0xFF00897B)),
    _MenuCard(title: 'Manage Dead Chicks', subtitle: 'Track dead chicks count', icon: Icons.pets, color: Color(0xFFD32F2F)),
    _MenuCard(title: 'Manage Feed Grains', subtitle: 'Track feed usage & stock', icon: Icons.grass_rounded, color: Color(0xFFE65100)),
    _MenuCard(title: 'Manage Medicine', subtitle: 'Track medicines & treatments', icon: Icons.medication_liquid_rounded, color: Color(0xFF0288D1)),
    _MenuCard(title: 'Manage Labour', subtitle: 'Staff records & wages', icon: Icons.engineering_rounded, color: Color(0xFF6A1B9A)),
    _MenuCard(title: 'Transaction History', subtitle: 'Payments received & paid with mode info', icon: Icons.receipt_long_rounded, color: Color(0xFF37474F)),
    _MenuCard(title: 'Reports & Backup', subtitle: 'Charts, export CSV & backup data', icon: Icons.bar_chart_rounded, color: Color(0xFF00695C)),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _cardControllers = List.generate(_menuItems.length, (i) => AnimationController(vsync: this, duration: Duration(milliseconds: 400 + i * 150)));
    _cardAnims = _cardControllers.map((c) => Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    for (var i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () => _cardControllers[i].forward());
    }
  }

  @override
  void dispose() {
    for (var c in _cardControllers) c.dispose();
    super.dispose();
  }

  void _onCardTap(int index) {
    _navigate(index);
  }

  void _navigate(int index) {
    Widget screen;
    switch (index) {
      case 0: screen = const AdminScreen(); break;
      case 1: screen = const CustomerScreen(); break;
      case 2: screen = const QuickUpdateScreen(); break;
      case 3: screen = const DeadChicksScreen(); break;
      case 4: screen = const FeedScreen(); break;
      case 5: screen = const MedicineScreen(); break;
      case 6: screen = const LabourScreen(); break;
      case 7: screen = const TransactionHistoryScreen(); break;
      case 8: screen = const ReportsScreen(); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cardControllers.length != _menuItems.length) {
      for (var c in _cardControllers) { c.dispose(); }
      _initAnimations();
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.egg_alt_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Poultry Farm', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            Text('Management System', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Main Menu', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              // Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: _menuItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) {
                      final item = _menuItems[i];
                      return SlideTransition(
                        position: _cardAnims[i],
                        child: FadeTransition(
                          opacity: _cardControllers[i],
                          child: _buildMenuCard(item, i),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(_MenuCard item, int index) {
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Icon(item.icon, color: item.color, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: item.color)),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: item.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_ios_rounded, color: item.color, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.color});
}
