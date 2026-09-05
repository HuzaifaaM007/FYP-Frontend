import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      return true;
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

  Future<bool> register(String email, String password, String fullName) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email, password, fullName);
      return true;
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
}