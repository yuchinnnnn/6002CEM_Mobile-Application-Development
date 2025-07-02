import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_page1.dart';
import 'signup_page2.dart';
import 'login_page.dart';

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
              child: Column(
                children: [
                  Text(
                    'Take control of your money.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Track your spending, manage your budget, and stay on top of your finances — all in one simple app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
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
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              icon: Icon(Icons.login, size: 18),
              label: Text('I have an account'),
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