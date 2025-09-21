import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'screens/splashscreen.dart';
import 'screens/history_page.dart';
import 'screens/signup_page.dart';
import 'screens/email_verification.dart';
import 'screens/home_page.dart';
import 'screens/wallet_page.dart';
import 'screens/email_payment_page.dart'; // Add this import


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file. Using default values.');
  }
  
  runApp(LedgerlyApp());
}

class LedgerlyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledgerly',
      theme: appTheme,
      home: SplashScreen(),
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/verify_email': (context) => const EmailVerificationPage(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;
        
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (context) => HomePage(
                userId: args?['userId'] ?? 0,
                userName: args?['userName'] ?? '',
                userEmail: args?['userEmail'] ?? '',
              ),
            );
            
          case '/history':
            return MaterialPageRoute(
              builder: (context) => HistoryPage(
                userId: args?['userId'] ?? 0,
                userName: args?['userName'] ?? '',
                userEmail: args?['userEmail'] ?? '',
              ),
            );
            
          case '/wallet':
            return MaterialPageRoute(
              builder: (context) => WalletPage(
                userId: args?['userId'] ?? 0,
                userName: args?['userName'] ?? '',
                userEmail: args?['userEmail'] ?? '',
              ),
            );
            
          case '/email_payment':
            return MaterialPageRoute(
              builder: (context) => EmailPaymentPage(
                userId: args?['userId'] ?? 0,
                userName: args?['userName'] ?? '',
                userEmail: args?['userEmail'] ?? '',
              ),
            );
            
          
            
          
        }
        
        // If route not found
        return null;
      },
    );
  }
}
