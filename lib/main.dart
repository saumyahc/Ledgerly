import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splashscreen.dart';
import 'screens/home_page.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: HomePage(),
  ));
}
