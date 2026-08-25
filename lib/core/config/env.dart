class Env {
  // Passed in via: flutter run --dart-define=API_BASE_URL=http://...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}