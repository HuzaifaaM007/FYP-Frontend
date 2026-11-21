import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/auth_service.dart';
import '../widgets/code_input.dart';

/// Two steps: 1) email -> we send a code; 2) code + new password -> signed in.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _service = AuthService();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  bool _hide = true;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown = (_cooldown - 1).clamp(0, 999));
      if (_cooldown == 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\.\-]+$').hasMatch(email)) {
      setState(() => _error = 'Enter the email you registered with.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _info = result.message;
      });
      _startCooldown(result.retryAfter > 0 ? result.retryAfter : 60);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final code = _code.text;
    final password = _password.text;
    if (code.length != 6) return setState(() => _error = 'Enter the 6-digit code from the email.');
    if (password.length < 8) return setState(() => _error = 'The new password must be at least 8 characters.');
    if (password != _confirm.text) return setState(() => _error = 'The passwords do not match.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.resetPassword(_email.text.trim(), code, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed. You are signed in.')));
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(_codeSent ? Icons.password_rounded : Icons.lock_reset_rounded, size: 44, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _codeSent ? 'Enter the code and a new password' : 'Forgot your password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'We sent a 6-digit code to ${_email.text.trim()}.'
                        : 'Enter your email and we will send you a code to set a new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (!_codeSent) ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _sendCode(),
                      decoration: const InputDecoration(hintText: 'Email'),
                    ),
                  ] else ...[
                    CodeInput(controller: _code, onCompleted: (_) {}, hasError: _error != null && _error!.contains('code')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: _hide,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: 'New password (at least 8 characters)',
                        suffixIcon: IconButton(
                          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: _hide,
                      onSubmitted: (_) => _reset(),
                      decoration: const InputDecoration(hintText: 'Confirm new password'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                  ] else if (_info != null && _codeSent) ...[
                    const SizedBox(height: 12),
                    Text(_info!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: _codeSent ? 'Set new password' : 'Send code',
                    isLoading: _busy,
                    onPressed: _codeSent ? _reset : _sendCode,
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _cooldown > 0 || _busy ? null : _sendCode,
                      child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : "Didn't get it? Resend code"),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _codeSent = false;
                                _error = null;
                                _code.clear();
                              }),
                      child: const Text('Use a different email'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
