
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/navigation/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            }
          },
          child: const Text('Log Out'),
        ),
      ),
    );
  }
}