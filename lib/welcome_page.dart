import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_page1.dart';
import 'signup_page1.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage ({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // App Title
            Text(
              "Spend Simple",
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Icons in a circular pattern (simplified)
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Logo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', width:280), // Replace with your logo
                    ],
                  ),
                ],
              ),
            ),

            // Subtitle / Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                "Track your daily spending, manage your budget, and take control of your finances — all in one simple app.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA07A), Color(0xFFFF6347)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrangeAccent.withOpacity(0.4),
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage1()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Get started",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),


            // Login Button
            TextButton(
              onPressed: () {},
              child: Text(
                "I have an account",
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget iconCircle(IconData icon, Color bgColor) {
    return CircleAvatar(
      backgroundColor: bgColor,
      radius: 30,
      child: Icon(icon, color: Colors.black87, size: 24),
    );
  }
}