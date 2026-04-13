import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_theme.dart';
import 'dashboard_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final setup = await AuthService.isSetup();
    if (!setup && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final success = await AuthService.login(_idController.text.trim(), _passController.text);
    setState(() => _isLoading = false);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      setState(() => _errorMessage = 'Invalid ID or Password. Please try again.');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: const Icon(Icons.egg_alt_rounded, size: 55, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Poultry Farm',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                      const Text(
                        'Management System',
                        style: TextStyle(fontSize: 15, color: Colors.white70, letterSpacing: 2),
                      ),
                      const SizedBox(height: 40),
                      // Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Welcome Back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              const Text('Sign in to your account', style: TextStyle(color: AppTheme.textSecondary)),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _idController,
                                decoration: const InputDecoration(
                                  labelText: 'Admin ID',
                                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
                                ),
                                validator: (v) => v!.isEmpty ? 'Enter Admin ID' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty ? 'Enter Password' : null,
                                onFieldSubmitted: (_) => _login(),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _isLoading
                                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                                  : ElevatedButton(
                                      onPressed: _login,
                                      child: const Text('LOGIN'),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
