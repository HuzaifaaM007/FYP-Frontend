import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/auth_service.dart';
import '../widgets/code_input.dart';

/// "Check your email" screen: enter the 6-digit code to verify the account and sign in.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _service = AuthService();
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _info;
  int _cooldown = 60; // a code was just sent when this screen opens
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
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

  Future<void> _verify([String? value]) async {
    final code = value ?? _code.text;
    if (code.length != 6 || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    try {
      await _service.verifyEmail(widget.email, code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified. Welcome to Study Sensei!')));
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _verifying = false;
      });
      _code.clear();
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final result = await _service.resendCode(widget.email);
      if (!mounted) return;
      setState(() => _info = result.message);
      if (result.retryAfter > 0) _startCooldown(result.retryAfter);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
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
                      child: Icon(Icons.mark_email_unread_outlined, size: 44, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Check your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                      children: [
                        const TextSpan(text: 'We sent a 6-digit code to\n'),
                        TextSpan(text: widget.email, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  CodeInput(controller: _code, onCompleted: _verify, hasError: _error != null, enabled: !_verifying),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                  ],
                  if (_info != null && _error == null) ...[
                    const SizedBox(height: 12),
                    Text(_info!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.success)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(label: 'Verify', isLoading: _verifying, onPressed: () => _verify()),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _cooldown > 0 || _resending ? null : _resend,
                    child: Text(
                      _resending
                          ? 'Sending…'
                          : _cooldown > 0
                              ? 'Resend code in ${_cooldown}s'
                              : "Didn't get it? Resend code",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The code expires in 10 minutes. Check your spam folder if you can\'t find it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
