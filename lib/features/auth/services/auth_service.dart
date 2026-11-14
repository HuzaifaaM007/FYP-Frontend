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
      await ApiClient.saveTokensFrom(response.data);
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
    try {
      await login(email, password);
    } on AuthException {
      throw AuthException('Account created, but automatic sign-in failed. Please log in manually.');
    }
  }

  /// True when a saved login exists and the server still accepts it (refreshing it if needed).
  Future<bool> hasValidSession() async {
    if (await SecureStorageService.getAccessToken() == null) return false;
    try {
      await _dio.get('/auth/me');
      return true;
    } on DioException catch (e) {
      // A network error should not throw the user out; let them in and the screens show their own retry.
      return e.response == null;
    }
  }

  Future<void> logout() async {
    final refresh = await SecureStorageService.getRefreshToken();
    if (refresh != null) {
      try {
        await _dio.post('/auth/logout', data: {'refresh_token': refresh});
      } catch (_) {
        // Signing out on this device is enough if the server cannot be reached.
      }
    }
    await SecureStorageService.clear();
  }

  Future<void> deleteAccount(String password) async {
    try {
      await _dio.delete('/auth/me', data: {'password': password});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) throw AuthException('That password is not correct.');
      if (e.response == null) throw AuthException('Could not reach the server. Try again.');
      throw AuthException('Could not delete your account. Please try again.');
    }
    await SecureStorageService.clear();
  }

  String _mapLoginError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return 'Incorrect email or password.';
    if (statusCode == 404) return 'No account found with that email.';
    if (statusCode == 422) return 'Enter a valid email address and password.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Login failed. Please try again.';
  }

  String _mapRegisterError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 409) return 'An account with this email already exists.';
    if (statusCode == 422) return 'Please check your details (password needs at least 8 characters).';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Registration failed. Please try again.';
  }
}
