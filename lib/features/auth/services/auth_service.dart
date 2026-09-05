import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthService {
  final _dio = ApiClient().dio;

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await SecureStorageService.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
    } on DioException catch (e) {
      throw AuthException(_mapLoginError(e));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
    } on DioException catch (e) {
      throw AuthException(_mapRegisterError(e));
    }
    // Only attempt auto-login once registration actually succeeded.
    try {
      await login(email, password);
    } on AuthException {
      // Registration worked but auto-login failed for some reason (e.g. slow
      // network right after signup) — don't mask this as a registration
      // failure, since the account genuinely was created.
      throw AuthException('Account created, but automatic sign-in failed. Please log in manually.');
    }
  }

  Future<void> logout() async {
    await SecureStorageService.clear();
  }

  String _mapLoginError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return 'Incorrect email or password.';
    }
    if (statusCode == 404) {
      return 'No account found with that email.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Login failed. Please try again.';
  }

  String _mapRegisterError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 409) {
      return 'An account with this email already exists.';
    }
    if (statusCode == 422) {
      return 'Please check your details and try again.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Registration failed. Please try again.';
  }
}