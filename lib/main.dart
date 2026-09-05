import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/screens/home_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'StudySensei',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const LoginScreen(),
        routes: {
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
