// lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _localError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(value);
  }

  Future<void> _handleRegister(AuthProvider auth) async {
    setState(() => _localError = null);
    auth.clearError();

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty) {
      setState(() => _localError = 'Please enter your name.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _localError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    final success = await auth.register(email, password, fullName);
    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final errorToShow = _localError ?? auth.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Study Sensei',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Create an account to start learning'),
              const SizedBox(height: 28),
              AppTextField(
                hint: 'Full name',
                controller: _fullNameController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Password',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              AppTextField(
                hint: 'Confirm password',
                controller: _confirmPasswordController,
                obscureText: true,
              ),
              if (errorToShow != null) ...[
                const SizedBox(height: 12),
                Text(errorToShow, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Create Account',
                isLoading: auth.isLoading,
                onPressed: () => _handleRegister(auth),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  auth.clearError();
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}