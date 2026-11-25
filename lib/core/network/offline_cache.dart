import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Saves the last successful answer of every GET request on the phone, per user,
/// so the app can still show it when the server cannot be reached.
class OfflineCache {
  OfflineCache._();

  static Directory? _dir;

  static Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  /// The user id inside the login token, so two accounts on one phone never see each other's data.
  static String userKeyFromToken(String? token) {
    if (token == null) return 'guest';
    try {
      final parts = token.split('.');
      if (parts.length < 2) return 'guest';
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return (payload['sub'] ?? 'guest').toString();
    } catch (_) {
      return 'guest';
    }
  }

  static String _fileName(String userKey, Uri uri) {
    final bytes = utf8.encode('$userKey|${uri.path}?${uri.query}');
    // Two 32-bit FNV-1a hashes: a short, safe file name for each user + page.
    int h1 = 0x811c9dc5, h2 = 0x01000193;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 0x01000193) & 0xFFFFFFFF;
      h2 = ((h2 ^ b) * 0x811c9dc5 + 7) & 0xFFFFFFFF;
    }
    return '${userKey}_${h1.toRadixString(16)}${h2.toRadixString(16)}_${bytes.length}.json';
  }

  static Future<void> save(String userKey, Uri uri, dynamic data) async {
    try {
      final file = File('${(await _folder()).path}/${_fileName(userKey, uri)}');
      await file.writeAsString(jsonEncode({'saved_at': DateTime.now().toIso8601String(), 'data': data}));
    } catch (_) {
      // Caching is best-effort; never break a request because of it.
    }
  }

  /// Returns the saved data, or null if this page was never loaded before.
  static Future<dynamic> read(String userKey, Uri uri) async {
    try {
      final file = File('${(await _folder()).path}/${_fileName(userKey, uri)}');
      if (!await file.exists()) return null;
      final saved = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return saved['data'];
    } catch (_) {
      return null;
    }
  }

  /// Called on logout.
  static Future<void> clearAll() async {
    try {
      final dir = await _folder();
      if (await dir.exists()) await dir.delete(recursive: true);
      _dir = null;
    } catch (_) {}
  }
}
