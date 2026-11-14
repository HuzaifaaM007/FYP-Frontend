import 'package:flutter/foundation.dart';

/// Lets the network layer tell the app "the login is no longer valid" without knowing about screens.
class SessionEvents {
  SessionEvents._();

  static final ValueNotifier<int> expired = ValueNotifier<int>(0);

  static void notifyExpired() => expired.value++;
}
