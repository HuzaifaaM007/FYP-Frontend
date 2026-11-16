import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_storage_service.dart';
import 'session_events.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // Only one refresh runs at a time; other failed requests wait for it and reuse the result.
  Completer<bool>? _refreshing;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      // AI calls (quiz, summary) can take over a minute when the model is cold.
      receiveTimeout: const Duration(seconds: 150),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageService.getAccessToken();
        if (token != null && !options.headers.containsKey('Authorization')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final isAuthCall = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        // The server itself could not be reached: tell the app so it can show one clear dialog.
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          SessionEvents.notifyConnectionLost(
            error.type == DioExceptionType.receiveTimeout
                ? 'The server took too long to respond. The AI service may be busy or paused.'
                : 'Could not reach the Study Sensei server. Check your internet connection, or that the server is running.',
          );
        }

        if (error.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
          final refreshed = await _refreshOnce();
          if (refreshed) {
            final request = error.requestOptions;
            request.extra['retried'] = true;
            request.headers['Authorization'] = 'Bearer ${await SecureStorageService.getAccessToken()}';
            try {
              return handler.resolve(await dio.fetch(request));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshOnce() {
    final running = _refreshing;
    if (running != null) return running.future;
    final completer = Completer<bool>();
    _refreshing = completer;
    _tryRefreshToken().then((ok) {
      completer.complete(ok);
      _refreshing = null;
    });
    return completer.future;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await saveTokensFrom(response.data);
      return true;
    } on DioException catch (e) {
      // Only a real rejection ends the session. A dropped connection should not log the user out.
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await SecureStorageService.clear();
        SessionEvents.notifyExpired();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// The backend answers `{user: {...}, tokens: {access_token, refresh_token}}`.
  /// A flat `{access_token, refresh_token}` shape is accepted too.
  static Future<void> saveTokensFrom(dynamic data) async {
    final map = data as Map<String, dynamic>;
    final tokens = (map['tokens'] as Map<String, dynamic>?) ?? map;
    await SecureStorageService.saveTokens(
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
    );
  }
}
