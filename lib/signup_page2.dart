import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage2 extends StatefulWidget {
  const SignupPage2({super.key});

  @override
  State<SignupPage2> createState() => _SignupPage2State();
}

class _SignupPage2State extends State<SignupPage2> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _password = '';
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;
  double _strengthBarWidthFactor = 0.0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = '';
        _strengthColor = Colors.grey;
        _strengthBarWidthFactor = 0.0;
      } else if (password.length < 6) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
        _strengthBarWidthFactor = 0.25;
      } else if (password.length < 10) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
        _strengthBarWidthFactor = 0.5;
      } else if (RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])').hasMatch(password)) {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
        _strengthBarWidthFactor = 1.0;
      } else {
        _passwordStrength = 'Good';
        _strengthColor = Colors.blue;
        _strengthBarWidthFactor = 0.75;
      }
    });
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

              const SizedBox(height: 100),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Email Field
              TextField(
                controller: _emailController,
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
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged: _checkPasswordStrength,
              ),

              const SizedBox(height: 5),

              // Password rule text
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Use 8 or more characters with a mix of letters, numbers & symbols.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_passwordStrength.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Password Strength: $_passwordStrength',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _strengthColor,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _strengthBarWidthFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _strengthColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Get Started Button (Gradient)
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
                      final username = _usernameController.text.trim();
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();

                      if (username.isEmpty || email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Username, email and password must not be empty',
                            ),
                          ),
                        );
                        return;
                      }

                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                      final user = FirebaseAuth.instance.currentUser;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .set({
                        'uid': user?.uid,
                        'username': username,
                        'password': password,
                        'email': email,
                        'createdAt': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Signup successful!')),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String message = '';
                      switch (e.code) {
                        case 'email-already-in-use':
                          message = 'This email is already in use.';
                          break;
                        case 'invalid-email':
                          message = 'The email address is invalid.';
                          break;
                        case 'weak-password':
                          message = 'The password is too weak.';
                          break;
                        default:
                          message = 'Signup failed: ${e.message}';
                      }

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An error occurred: ${e.toString()}'),
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
                    "Get started, it’s free!",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 100),

              // Already have account
              const Text("Do you have already an account?"),

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
                        builder: (context) => const LoginPage(),
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black, // or your theme's primary color
                      ),
                    ),
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
