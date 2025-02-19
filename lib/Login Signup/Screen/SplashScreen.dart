import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hear_aid/Login%20Signup/Screen/login.dart';
import 'package:hear_aid/Home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a timer to wait for 3 seconds before navigating
    Timer(const Duration(seconds: 3), _checkUserStatus);
  }

  void _checkUserStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If the user is logged in, navigate to HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // If the user is not logged in, navigate to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // You can change the color as needed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the Image.asset widget to display the image
            Image.asset(
              'images/logo.png', // Path to your image
              width: 150, // Adjust the size as necessary
              height: 150,
            ),
            const SizedBox(height: 20),
        Text(
          "Welcome to Hear Aid",
          style: GoogleFonts.roboto(
            fontSize: 24, // Font size
            fontWeight: FontWeight.bold, // Bold font
            color: Colors.blue, // Font color
          )
          ),
          ],
        ),
      ),
    );
  }
}
