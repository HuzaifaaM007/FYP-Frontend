import 'package:flutter/foundation.dart';

/// Lets the network layer tell the app about session/connection problems without knowing about screens.
class SessionEvents {
  SessionEvents._();

  /// Bumped when the login is no longer valid (the app restarts at the splash screen).
  static final ValueNotifier<int> expired = ValueNotifier<int>(0);

  /// Set to a message when the server cannot be reached (no network, backend down, wrong IP).
  static final ValueNotifier<String?> connectionLost = ValueNotifier<String?>(null);

  static void notifyExpired() => expired.value++;

  static void notifyConnectionLost(String message) {
    // Re-assign even if the text is the same so every listener fires.
    connectionLost.value = null;
    connectionLost.value = message;
  }
}
