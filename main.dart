import 'package:flutter/material.dart';
import 'rotas.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Softinsa',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
