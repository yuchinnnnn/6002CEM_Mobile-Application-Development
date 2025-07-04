import 'package:flutter/material.dart';
import 'package:spend_simple/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'summary_page.dart';
import 'spending_page.dart';
import 'profile_page.dart';
import 'add_record_page.dart';
import 'theme_provider.dart';
import 'widget/main_scaffold.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Spend Simple',
      debugShowCheckedModeBanner: false,
      theme:
      ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      navigatorObservers: [routeObserver],
      // themeMode: themeProvider.themeMode,
      // darkTheme: ThemeData.dark(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const MainScaffold();
          } else {
            return const WelcomePage();
          }
        },
      ),


    );
  }
}
