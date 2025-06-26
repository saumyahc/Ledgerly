// auth_input_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_verification_page.dart';

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

  bool _isPhoneNumber(String input) {
    // Enhanced phone number validation with country code
    return RegExp(r'^\+\d{1,3}\d{10,14}$').hasMatch(input);
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
          // FIX: Prevent overflow
          padding: EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.blue),
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
                  'Enter your email or phone number to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone Number',
                    hintText: 'Enter email or +1234567890',
                    prefixIcon: Icon(Icons.person_outline),
                    suffixIcon: _controller.text.isNotEmpty
                        ? Icon(
                            _isEmail(_controller.text)
                                ? Icons.email_outlined
                                : _isPhoneNumber(_controller.text)
                                ? Icons.phone_outlined
                                : Icons.help_outline,
                            color:
                                _isEmail(_controller.text) ||
                                    _isPhoneNumber(_controller.text)
                                ? Colors.green
                                : Colors.grey,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {}); // Refresh to show the suffix icon
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  // FIX: Constrain button height
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
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
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'We\'ll automatically detect if it\'s an email or phone number',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                // FIX: Add instructions for phone format
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'For phone numbers, please include country code (e.g., +1 for US, +91 for India)',
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

  Future<void> _handleSubmit() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      _showErrorDialog('Please enter an email or phone number.');
      return;
    }

    if (_isEmail(input)) {
      await _handleEmailSignIn(input);
    } else if (_isPhoneNumber(input)) {
      await _handlePhoneSignIn(input);
    } else {
      _showErrorDialog(
        'Please enter a valid email or phone number with country code (e.g., +1234567890).',
      );
    }
  }

  Future<void> _handleEmailSignIn(String email) async {
    setState(() => _isLoading = true);

    try {
      // FIX: Use createUserWithEmailAndPassword or signInWithEmailAndPassword instead
      // Since email link sign-in requires additional setup

      // For now, let's try a simple email/password approach
      // You can modify this based on your requirements

      // Option 1: Create account (if new user)
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: 'temp123');

        _showSuccessDialog(
          'Account Created',
          'Welcome! Your account has been created.',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Option 2: Try to send password reset (if existing user)
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          _showSuccessDialog(
            'Password Reset',
            'A password reset link has been sent to your email.',
          );
        } else {
          throw e;
        }
      }
    } catch (e) {
      _showErrorDialog('Email authentication error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhoneSignIn(String phoneNumber) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            setState(() => _isLoading = false);
            _showSuccessDialog(
              'Success',
              'Phone number verified automatically!',
            );
          } catch (e) {
            setState(() => _isLoading = false);
            _showErrorDialog('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          String errorMessage = 'Phone verification failed.';

          if (e.code == 'billing-not-enabled') {
            errorMessage =
                'Phone authentication requires billing to be enabled in Firebase Console.';
          } else if (e.code == 'invalid-phone-number') {
            errorMessage =
                'Invalid phone number format. Please include country code.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later.';
          }

          _showErrorDialog(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() => _isLoading = false);
        },
        timeout: Duration(seconds: 60), // FIX: Add timeout
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Phone verification setup failed: ${e.toString()}');
    }
  }
}
