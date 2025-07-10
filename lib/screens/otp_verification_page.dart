// otp_verification_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final bool isSignUp;
  final Map<String, dynamic>? userData;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.isSignUp,
    this.userData,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
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
            onPressed: () {
              Navigator.pop(context);
              // Navigate to home page after successful verification
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
              );
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showErrorDialog('Please enter the OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String endpoint = widget.isSignUp
          ? 'http://localhost/Ledgerly/Ledgerly/backend_example/verify_signup_otp.php'
          : 'http://localhost/Ledgerly/Ledgerly/backend_example/verify_otp.php';

      Map<String, String> body = {'email': widget.email, 'otp': otp};

      // Add user data for sign-up verification
      if (widget.isSignUp && widget.userData != null) {
        body.addAll(
          widget.userData!.map((key, value) => MapEntry(key, value.toString())),
        );
      }

      final response = await http.post(Uri.parse(endpoint), body: body);

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() => _isLoading = false);
        _showSuccessDialog(
          'Success',
          widget.isSignUp
              ? 'Account created successfully! Welcome to Ledgerly.'
              : 'Email verified successfully!',
        );
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(data['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to verify OTP: $e');
    }
  }

  Future<void> _handleResendOTP() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    try {
      String endpoint = widget.isSignUp
          ? 'http://localhost/Ledgerly/Ledgerly/backend_example/signup.php'
          : 'http://localhost/Ledgerly/Ledgerly/backend_example/send_otp.php';

      Map<String, String> body = {'email': widget.email};

      // Add user data for sign-up resend
      if (widget.isSignUp && widget.userData != null) {
        body.addAll(
          widget.userData!.map((key, value) => MapEntry(key, value.toString())),
        );
      }

      final response = await http.post(Uri.parse(endpoint), body: body);

      final data = jsonDecode(response.body);

      if (data['success']) {
        setState(() => _isResending = false);
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isResending = false);
        _showErrorDialog(data['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      setState(() => _isResending = false);
      _showErrorDialog('Failed to resend OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_outlined, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'We\'ve sent a verification code to',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '000000',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 24),

              // Verify Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOTP,
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
              SizedBox(height: 24),

              // Resend OTP Section
              Column(
                children: [
                  Text(
                    'Didn\'t receive the code?',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  if (_canResend)
                    TextButton(
                      onPressed: _isResending ? null : _handleResendOTP,
                      child: _isResending
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    )
                  else
                    Text(
                      'Resend OTP in $_resendTimer seconds',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                ],
              ),
              SizedBox(height: 24),

              // Info Box
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Enter the 6-digit code sent to your email address. The code will expire in 10 minutes.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
