// signup_page1.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spend_simple/signup_page2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class SignupPage1 extends StatefulWidget {
  const SignupPage1({super.key});

  @override
  State<SignupPage1> createState() => _SignupPage1State();
}

class _SignupPage1State extends State<SignupPage1> {

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(clientId: '380869353358-u6smm901d6p3j1p3uvqq1dqji7otnnup.apps.googleusercontent.com')
          : GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user to Firestore if not exists
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'username': user.displayName,
          'email': user.email,
          // 'password': user.password,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigate to homepage
      Navigator.pushReplacementNamed(context, '/home'); // or use MaterialPageRoute

    } catch (e) {
      print("❌ Google Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Google Sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      // appBar: AppBar(title: const Text("Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center Logo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', width:250), // Replace with your logo
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => signInWithGoogle(context),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Keeps the button compact
                        children: [
                          Icon(Icons.g_mobiledata_rounded, color: Colors.black), // You can replace this with a custom Google icon
                          SizedBox(width: 8), // Spacing between icon and text
                          Text(
                            "Sign Up with Google",
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),

                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1771E6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(builder: (context) => const LoginPage()));
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Keeps the button compact
                        children: [
                          Icon(Icons.facebook_outlined, color: Colors.white), // You can replace this with a custom Google icon
                          SizedBox(width: 8), // Spacing between icon and text
                          Text(
                            "Sign Up with Facebook",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
                child:
                Text(
                    "or",
                    style: TextStyle(fontWeight: FontWeight.bold)
                )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child:
                  TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage2()));
                      },
                    child: Text(
                      'Sign Up with Email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black
                      ),
                  )
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              child: Center(
                child: Text(
                    "By registering, you agree to our Terms of Use. Learn how we collect, use and share your data.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          ],
        )
      ),
    );
  }
}
