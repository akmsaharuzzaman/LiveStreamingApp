import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlstarlive/features/core/services/login_provider.dart';

class MainProfileScreen extends StatelessWidget {
  const MainProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This feature will be implemented soon.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Clear shared preferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    
                    // Update the login provider
                    if (context.mounted) {
                      context.read<LoginInfo>().logout();
                      // Use go instead of pushReplacement to completely reset navigation
                      context.go('/welcome-screen');
                    }
                  } catch (e) {
                    debugPrint('Error during logout: $e');
                    // Still try to navigate even if there's an error
                    if (context.mounted) {
                      context.go('/welcome-screen');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
