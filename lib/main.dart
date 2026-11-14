import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/main_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/providers/home_provider.dart';
import 'features/planner/providers/planner_provider.dart';
import 'features/lectures/providers/lecture_list_provider.dart';
import 'features/notifications/screens/notifications_placeholder_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const StudySenseiApp(),
    ),
  );
}

class StudySenseiApp extends StatelessWidget {
  const StudySenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // When this number changes (sign out, deleted account, expired session) everything below is rebuilt
    // from scratch: the old user's data and screens are gone and the app starts again at the splash screen.
    final sessionId = context.select<AuthProvider, int>((auth) => auth.sessionId);

    return MultiProvider(
      key: ValueKey(sessionId),
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => LectureListProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
      ],
      child: MaterialApp(
        title: 'Study Sensei',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const MainShell(),
          AppRoutes.notifications: (_) => const NotificationsPlaceholderScreen(),
        },
      ),
    );
  }
}
