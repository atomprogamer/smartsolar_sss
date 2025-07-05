import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/auth_provider.dart';
import '../utils/routes.dart';
import '../utils/theme.dart';

/// Splash screen shown when the app starts
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate to the appropriate screen after a delay
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Navigate to the next screen based on authentication status
  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for animations to complete
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is logged in
      if (authProvider.isLoggedIn) {
        // Refresh user data
        await authProvider.refreshUser();

        if (!mounted) return;

        // Navigate to the appropriate dashboard based on user type
        if (authProvider.isAdmin) {
          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.adminDashboard);
        } else if (authProvider.isExpert) {
          AppRoutes.navigateAndRemoveUntil(context, AppRoutes.expertDashboard);
        } else if (authProvider.isTechnician) {
          AppRoutes.navigateAndRemoveUntil(
            context,
            AppRoutes.technicianDashboard,
          );
        } else {
          AppRoutes.navigateAndRemoveUntil(
            context,
            AppRoutes.customerDashboard,
          );
        }
      } else {
        // Navigate to welcome screen
        AppRoutes.navigateAndRemoveUntil(context, AppRoutes.welcome);
      }
    } catch (e) {
      print('Error in splash screen navigation: $e');

      if (!mounted) return;

      // Navigate to welcome screen in case of error
      AppRoutes.navigateAndRemoveUntil(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.solar_power,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // App name
                    Text(
                      'Smart Solar Solution',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tagline
                    Text(
                      'Powering Pakistan with Solar Energy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Loading indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
