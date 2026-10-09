import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Brand colors (imported implicitly in main or defined here)
const Color brandGreen = Color(0xFF135B26);
const Color brandBg = Color(0xFFF6F8FC);
const Color brandDark = Color(0xFF0F172A);
const Color brandGray = Color(0xFF64748B);

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isFirstTime = false;


  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _checkFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool firstTime = prefs.getBool('is_first_time_launch') ?? true;

      if (!firstTime) {
        await Future.delayed(const Duration(milliseconds: 1500));
        _navigateToNext();
      } else {
        if (mounted) {
          setState(() {
            isFirstTime = true;
          });
        }
      }
    } catch (e) {
      // Fallback if shared preferences fails
      await Future.delayed(const Duration(milliseconds: 1500));
      _navigateToNext();
    }
  }

  void _onNextClicked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_time_launch', false);
    } catch (e) {
      // Proceed anyway if it fails
    }
    _navigateToNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/mdhk_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant, size: 80, color: brandGreen),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Welcome to Hostel Mess",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: brandDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Manage your daily meals easily",
                style: TextStyle(
                  fontSize: 16,
                  color: brandGray,
                ),
              ),
              const Spacer(),
              if (isFirstTime)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _onNextClicked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Next / Get Started",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isFirstTime)
                const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

