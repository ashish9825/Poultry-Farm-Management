import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_theme.dart';
import 'login_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  Future<void> _setup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await AuthService.setupAdmin(
      adminId: _idCtrl.text.trim(),
      password: _passCtrl.text,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup complete! Please login.'), backgroundColor: AppTheme.primary),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose(); _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 70, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('First Time Setup', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Create your admin account', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _idCtrl,
                            decoration: const InputDecoration(labelText: 'Admin ID', prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.primary)),
                            validator: (v) => v!.length < 3 ? 'Min 3 characters' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscurePass,
                            decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary)),
                            validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 14),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                              : ElevatedButton(onPressed: _setup, child: const Text('CREATE ACCOUNT')),
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
    );
  }
}
