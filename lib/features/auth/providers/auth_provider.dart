import 'package:flutter/material.dart';
import '../../../core/network/session_events.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  /// Bumped whenever the user signs out or the session ends. main.dart uses it to rebuild the app,
  /// which throws away every screen and provider so the next account never sees the previous one's data.
  int sessionId = 0;

  AuthProvider() {
    SessionEvents.expired.addListener(_onExpired);
  }

  @override
  void dispose() {
    SessionEvents.expired.removeListener(_onExpired);
    super.dispose();
  }

  void _onExpired() {
    errorMessage = 'Your session expired. Please sign in again.';
    sessionId++;
    notifyListeners();
  }

  Future<bool> restoreSession() => _authService.hasValidSession();

  /// Set when login/register needs the email code; the screen then opens VerifyEmailScreen.
  String? pendingVerificationEmail;

  Future<bool> login(String email, String password) => _run(() => _authService.login(email, password));

  Future<bool> register(String email, String password, String fullName) =>
      _run(() => _authService.register(email, password, fullName));

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    pendingVerificationEmail = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on EmailNotVerifiedException catch (e) {
      pendingVerificationEmail = e.email;
      return false;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    errorMessage = null;
    sessionId++;
    notifyListeners();
  }

  /// Returns null on success, otherwise a message to show.
  Future<String?> deleteAccount(String password) async {
    try {
      await _authService.deleteAccount(password);
    } on AuthException catch (e) {
      return e.message;
    }
    errorMessage = null;
    sessionId++;
    notifyListeners();
    return null;
  }
}
