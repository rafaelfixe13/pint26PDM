import 'package:flutter/material.dart';
import 'package:pinttest/screens/login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Softinsa',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}
