import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../shared/providers/auth_providers.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final obscurePassword = useState(true);

    Future<void> handleLogin() async {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email dan Password harus diisi')),
        );
        return;
      }

      isLoading.value = true;
      try {
        await ref.read(authRepositoryProvider).signIn(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Gagal: ${e.toString()}')),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // Centered Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D7423).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bug_report_rounded,
                  size: 64,
                  color: Color(0xFF1D7423),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SIKADERCANTIK',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1D7423),
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Sistem Kader Pencatatan Jentik',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Masuk ke Akun Anda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Email Anda',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => obscurePassword.value = !obscurePassword.value,
                  ),
                ),
                obscureText: obscurePassword.value,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading.value ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D7423),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'MASUK',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Lupa Password?',
                  style: TextStyle(
                    color: Color(0xFF1D7423),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
