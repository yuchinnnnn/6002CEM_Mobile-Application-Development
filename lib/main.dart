import 'package:flutter/material.dart';
import 'package:spend_simple/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🟢 Needed before Firebase init

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBXpTbYFnkNN2b88lcMjo_Yx_1RZrBJ1ys',
      appId: '1:380869353358:android:db4a1d2d6918bd817b4edf',
      messagingSenderId: '380869353358',
      projectId: 'spen-f433d',
    ),
  );

  runApp(const MyApp()); // 🔵 Only after Firebase is initialized
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spend Simple',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WelcomePage(),
    );
  }
}
