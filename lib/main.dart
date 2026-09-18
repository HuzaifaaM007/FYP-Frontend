import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_routes.dart';
import 'core/navigation/main_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/providers/home_provider.dart';
import 'features/planner/providers/planner_provider.dart';
import 'features/lectures/providers/lecture_list_provider.dart';
import 'features/notifications/screens/notifications_placeholder_screen.dart';

void main() {
  runApp(const StudySenseiApp());
}

class StudySenseiApp extends StatelessWidget {
  const StudySenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => LectureListProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
      ],
      child: MaterialApp(
        title: 'Study Sensei',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.home: (_) => const MainShell(),
          AppRoutes.notifications: (_) =>
              const NotificationsPlaceholderScreen(),
        },
      ),
    );
  }
}
