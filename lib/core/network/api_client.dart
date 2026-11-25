import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/secure_storage_service.dart';
import 'offline_cache.dart';
import 'session_events.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // Needed when the backend is reached through ngrok (skips its browser warning page).
  static const Map<String, String> _commonHeaders = {'ngrok-skip-browser-warning': 'true'};

  // Only one refresh runs at a time; other failed requests wait for it and reuse the result.
  Completer<bool>? _refreshing;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      headers: _commonHeaders,
      connectTimeout: const Duration(seconds: 10),
      // AI calls (quiz, summary, narration) can take over a minute when the model is cold.
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
      onResponse: (response, handler) async {
        // Remember the last good answer of every page, for when the server is offline.
        if (_cacheable(response.requestOptions) && (response.statusCode ?? 0) < 300) {
          final token = await SecureStorageService.getAccessToken();
          await OfflineCache.save(OfflineCache.userKeyFromToken(token), response.requestOptions.uri, response.data);
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final isAuthCall = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/refresh');
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        // The server itself could not be reached (no internet, backend stopped, ngrok offline).
        if (_isOffline(error)) {
          // Show what was loaded last time instead of an error, if we have it.
          if (_cacheable(error.requestOptions)) {
            final token = await SecureStorageService.getAccessToken();
            final saved = await OfflineCache.read(OfflineCache.userKeyFromToken(token), error.requestOptions.uri);
            if (saved != null) {
              SessionEvents.notifyConnectionLost(
                'You are offline or the Study Sensei server is not running. '
                'Showing what was saved on your phone last time; new changes will not load until you are back online.',
              );
              return handler.resolve(Response(
                requestOptions: error.requestOptions,
                data: saved,
                statusCode: 200,
                extra: {'fromCache': true},
              ));
            }
          }
          SessionEvents.notifyConnectionLost(
            error.type == DioExceptionType.receiveTimeout
                ? 'The server took too long to respond. The AI service may be busy or paused.'
                : 'Could not reach the Study Sensei server. Check your internet connection, or that the server is running.',
          );
        }

        if (error.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
          final request = error.requestOptions;
          final sentWith = (request.headers['Authorization'] as String?)?.replaceFirst('Bearer ', '');
          final current = await SecureStorageService.getAccessToken();

          // This request left with an old token, but another request has already refreshed it:
          // just send it again with the new token instead of refreshing a second time.
          final alreadyRefreshed = current != null && sentWith != null && current != sentWith;
          final ok = alreadyRefreshed || await _refreshOnce();

          if (ok) {
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

  /// Only normal JSON GET requests are saved (not login, not audio files, not live status checks).
  static bool _cacheable(RequestOptions o) {
    if (o.method.toUpperCase() != 'GET') return false;
    if (o.responseType != ResponseType.json) return false;
    const skip = ['/auth/', '/ai/status', '/health'];
    return !skip.any((s) => o.path.contains(s));
  }

  /// True when the server could not be reached at all, including ngrok's own error
  /// pages when the laptop backend is stopped.
  static bool _isOffline(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final headers = e.response?.headers;
    if (headers != null && headers.value('ngrok-error-code') != null) return true;
    final code = e.response?.statusCode;
    return code == 502 || code == 503 || code == 504;
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
      final response = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl, headers: _commonHeaders)).post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await saveTokensFrom(response.data);
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        // If the saved refresh token changed while we were waiting, another refresh already
        // succeeded: the user is still signed in, so do NOT log them out.
        final latest = await SecureStorageService.getRefreshToken();
        if (latest != null && latest != refreshToken) return true;
        await SecureStorageService.clear();
        SessionEvents.notifyExpired();
      }
      // A dropped connection should not log the user out.
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
