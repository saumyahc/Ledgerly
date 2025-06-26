// otp_verification_page.dart 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class OtpVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  OtpVerificationPage({
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _resendTimer--;
      });
      
      if (_resendTimer == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      _showErrorDialog('Please enter all 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Success - navigate to next screen or show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to main screen or dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      String errorMessage = 'Invalid OTP. Please try again.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid verification code. Please check and try again.';
            break;
          case 'code-expired':
            errorMessage = 'Verification code has expired. Please request a new one.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Please try again later.';
            break;
        }
      }
      
      _showErrorDialog(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: widget.resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Phone verified automatically!')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } catch (e) {
            _showErrorDialog('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Failed to resend OTP.';
          
          if (e.code == 'billing-not-enabled') {
            errorMessage = 'SMS service requires billing to be enabled in Firebase Console.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later.';
          }
          
          _showErrorDialog(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          // Update verification ID for the new code
          setState(() {
            // You might want to update the verification ID here
          });
          
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent again!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      _showErrorDialog('Failed to resend OTP: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-verify when all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _verifyOTP();
    }
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
        child: SingleChildScrollView( // FIX: Prevent overflow
          padding: EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       kToolbarHeight - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 32),
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'We\'ve sent a 6-digit code to',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48),
                // FIX: Improved OTP input layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 45,
                      height: 55,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) => _onOtpChanged(value, index),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 32),
                SizedBox( // FIX: Constrain button height
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
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
                              fontWeight: FontWeight.w600
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive the code? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendOTP : null,
                      child: Text(
                        _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                        style: TextStyle(
                          fontSize: 14,
                          color: _canResend ? Colors.blue : Colors.grey[400],
                          fontWeight: FontWeight.w600,
                          decoration: _canResend ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // FIX: Add clear button
                TextButton(
                  onPressed: () {
                    for (var controller in _controllers) {
                      controller.clear();
                    }
                    _focusNodes[0].requestFocus();
                  },
                  child: Text(
                    'Clear OTP',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}