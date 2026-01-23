import 'package:flutter/material.dart';
import 'package:ku_lost_found/home_page.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KU Lost & Found',
      theme: ThemeData(
        fontFamily: 'Line Seed Sans TH',
      ),
      home: const HomePage(),
    );
  }
}
