import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

/// Login/register worked, but the student must enter the code we emailed first.
class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;
  EmailNotVerifiedException(this.email, this.message);
}

/// Answer of resend-code / forgot-password.
class CodeRequestResult {
  final bool sent;
  final int retryAfter; // seconds until another code can be requested
  final String message;
  const CodeRequestResult(this.sent, this.retryAfter, this.message);

  factory CodeRequestResult.fromJson(Map data) => CodeRequestResult(
        data['sent'] == true,
        (data['retry_after'] as num?)?.toInt() ?? 0,
        data['message'] as String? ?? '',
      );
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
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      if (e.response?.statusCode == 403 && detail is Map && detail['code'] == 'email_not_verified') {
        throw EmailNotVerifiedException(detail['email'] as String? ?? email, detail['message'] as String? ?? '');
      }
      throw AuthException(_mapLoginError(e));
    }
  }

  /// Creates the account. Students then get an email code (throws EmailNotVerifiedException so the
  /// app opens the code screen); admin emails are signed in straight away.
  Future<void> register(String email, String password, String fullName) async {
    Response response;
    try {
      response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
    } on DioException catch (e) {
      throw AuthException(_mapRegisterError(e));
    }
    final data = response.data;
    if (data is Map && data['verification_required'] == true) {
      throw EmailNotVerifiedException(data['email'] as String? ?? email, 'We sent a 6-digit code to your email.');
    }
    await ApiClient.saveTokensFrom(data);
  }

  // ---------------------------------------------------------------- email codes
  Future<void> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post('/auth/verify-email', data: {'email': email, 'code': code});
      await ApiClient.saveTokensFrom(response.data);
    } on DioException catch (e) {
      throw AuthException(_detailOr(e, 'Could not verify the code. Please try again.'));
    }
  }

  Future<CodeRequestResult> resendCode(String email) async {
    try {
      final response = await _dio.post('/auth/resend-code', data: {'email': email});
      return CodeRequestResult.fromJson(response.data as Map);
    } on DioException catch (e) {
      throw AuthException(_detailOr(e, 'Could not send a new code. Please try again.'));
    }
  }

  Future<CodeRequestResult> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {'email': email});
      return CodeRequestResult.fromJson(response.data as Map);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw AuthException('Enter a valid email address.');
      throw AuthException(_detailOr(e, 'Could not send the reset code. Please try again.'));
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      await ApiClient.saveTokensFrom(response.data);
    } on DioException catch (e) {
      throw AuthException(_detailOr(e, 'Could not reset your password. Please try again.'));
    }
  }

  String _detailOr(DioException e, String fallback) {
    if (e.response == null) return 'Could not reach the server. Check your connection and try again.';
    final data = e.response!.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return fallback;
  }

  /// True when a saved login exists and the server still accepts it (refreshing it if needed).
  /// Decides instantly from the saved login, so the app opens straight away even when the
  /// server is down or slow. The real check runs in the background right after:
  /// - expired/invalid login  -> the network layer refreshes it, or sends the user back to Login;
  /// - server unreachable     -> the app shows its "Connection problem" dialog, screens show Retry.
  Future<bool> hasValidSession() async {
    if (await SecureStorageService.getAccessToken() == null) return false;
    _dio.get('/auth/me').catchError((_) => Response(requestOptions: RequestOptions()));
    return true;
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
    if (statusCode == 409) return 'An account with this email already exists. Try logging in, or use "Forgot password?".';
    if (statusCode == 400) {
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) return data['detail'] as String;
    }
    if (statusCode == 422) return 'Please check your details (password needs at least 8 characters).';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Registration failed. Please try again.';
  }
}
