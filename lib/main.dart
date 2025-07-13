import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splashscreen.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: SplashScreen(),
  ));
}
