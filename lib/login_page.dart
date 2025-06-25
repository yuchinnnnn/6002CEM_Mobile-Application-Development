import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'signup_page2.dart';
import 'signup_page1.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = const FlutterSecureStorage();

  bool isChecked = false;
  final TextEditingController _loginEmail = TextEditingController();
  final TextEditingController _loginPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    String? savedEmail = await _storage.read(key: 'email');
    String? savedPassword = await _storage.read(key: 'password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _loginEmail.text = savedEmail;
        _loginPassword.text = savedPassword;
        isChecked = true;
      });
    }
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf2ede9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Title
              const Text(
                "Spend Simple",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono',
                ),
              ),

              const SizedBox(height: 80),

              // Email Field
              TextField(
                controller: _loginEmail, // ✅ Controller added
                decoration: InputDecoration(
                  labelText: "E-mail address",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _loginPassword, // ✅ Controller added
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                  ),
                  const Text("Remember me"),
                  Padding(
                    padding: const EdgeInsets.only(left: 180),
                    child: Text('Forget Password'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA07A), Color(0xFFFF6347)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrangeAccent.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final email = _loginEmail.text.trim();
                      final password = _loginPassword.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Email and password must not be empty',
                            ),
                          ),
                        );
                        return;
                      }

                      // ✅ Use login instead of signup
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      // ✅ Save login info if "Remember me" is checked
                      if (isChecked) {
                        await _storage.write(key: 'email', value: email);
                        await _storage.write(key: 'password', value: password);
                      } else {
                        await _storage.deleteAll();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Login successful!')),
                      );

                      // TODO: Navigate to the home page or dashboard after login
                      // Replace LoginPage with your actual home screen widget
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                          const HomePage(), // ← Replace with your home page
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String message = '';
                      switch (e.code) {
                        case 'user-not-found':
                          message = 'No user found for that email.';
                          break;
                        case 'wrong-password':
                          message = 'Wrong password provided.';
                          break;
                        case 'invalid-email':
                          message = 'The email address is invalid.';
                          break;
                        default:
                          message = 'Login failed: ${e.message}';
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'An error occurred: ${e.toString()}',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 50,
                    ),
                  ),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 100),

              // Already have account
              const Text("Don't have an account yet?"),

              const SizedBox(height: 20),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to login
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupPage1(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
