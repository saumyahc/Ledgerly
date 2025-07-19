// auth_input_page.dart (Mobile App)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class AuthInputPage extends StatefulWidget {
  @override
  _AuthInputPageState createState() => _AuthInputPageState();
}

class _AuthInputPageState extends State<AuthInputPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  bool _isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.email_outlined, size: 80, color: Colors.blue),
                SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your email address to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                    suffixIcon: _controller.text.isNotEmpty
                        ? Icon(
                            _isEmail(_controller.text)
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _isEmail(_controller.text)
                                ? Colors.green
                                : Colors.red,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send Verification Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'We\'ll send you a verification link to your email. Click the link to complete authentication.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailSubmit() async {
    final email = _controller.text.trim();

    if (email.isEmpty) {
      _showErrorDialog('Please enter an email address.');
      return;
    }

    if (!_isEmail(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Store email for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_email', email);

      // Configure action code settings for email link
      final actionCodeSettings = ActionCodeSettings(
        // This should point to your Flutter web app
        url: 'https://your-flutter-web-domain.com/#/auth-verify?email=$email',
        handleCodeInApp: false,
        iOSBundleId: 'com.yourapp.bundleid',
        androidPackageName: 'com.yourapp.packagename',
        androidInstallApp: true,
        androidMinimumVersion: '1',
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      setState(() => _isLoading = false);

      _showSuccessDialog(
        'Verification Email Sent',
        'Please check your email and click the verification link to continue.',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to send verification email: ${e.toString()}');
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        // User is signed in, navigate to wallet page
        Navigator.pushReplacementNamed(context, '/wallet');
      }
    });
  }
}

class ContactEmailPage extends StatelessWidget {
  const ContactEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Contact Us', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Glass3DCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.email, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Contact Support',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppColors.primary, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Send us your query or feedback and we’ll get back to you soon!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                          labelText: 'Your Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: AppColors.primary),
                          labelText: 'Your Email',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.message, color: AppColors.primary),
                          labelText: 'Message',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Neumorphic3DButton(
                          child: Text('Send', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
