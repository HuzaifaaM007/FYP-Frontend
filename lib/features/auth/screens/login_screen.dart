import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Study Sensei',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Welcome back', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AppTextField(hint: 'Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AppTextField(hint: 'Password', controller: _passwordController, obscureText: true),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(auth.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Continue',
                isLoading: auth.isLoading,
                onPressed: () async {
                  final success = await auth.login(_emailController.text.trim(), _passwordController.text);
                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  auth.clearError();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}