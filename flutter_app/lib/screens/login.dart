import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;

  Future<void> _signIn() async {
    setState(() => loading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _signIn,
                icon: const Icon(Icons.login),
                label: const Text('Google ile Giriş Yap')),
      ),
    );
  }
}
