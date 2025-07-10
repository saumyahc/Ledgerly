// auth_input_page.dart (Mobile App)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_page.dart';

class AuthInputPage extends StatefulWidget {
  const AuthInputPage({super.key});

  @override
  _AuthInputPageState createState() => _AuthInputPageState();
}

class _AuthInputPageState extends State<AuthInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

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
              minHeight:
                  MediaQuery.of(context).size.height -
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
                  !_otpSent
                      ? 'Enter your email address to continue'
                      : 'Enter the OTP sent to your email',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                if (!_otpSent) ...[
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
                      onPressed: _isLoading ? null : _handleSendOtp,
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
                              'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerifyOtp,
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
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    !_otpSent
                        ? 'We\'ll send you an OTP to your email. Enter it here to complete authentication.'
                        : 'Enter the OTP you received in your email inbox.',
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

  Future<void> _handleSendOtp() async {
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
      final response = await http.post(
        Uri.parse(
          'http://localhost/Ledgerly/Ledgerly/backend_example/send_otp.php',
        ),
        body: {'email': email},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _showSuccessDialog('OTP Sent', 'Check your email for the OTP.');
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(data['message']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to send OTP: $e');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _controller.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showErrorDialog('Please enter the OTP.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost/Ledgerly/Ledgerly/backend_example/verify_otp.php',
        ),
        body: {'email': email, 'otp': otp},
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() => _isLoading = false);
        _showSuccessDialog('Verified', 'Your email has been verified.');
        // Navigate to next page or perform login
        // Navigator.pushReplacementNamed(context, '/wallet');
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(data['message']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to verify OTP: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
