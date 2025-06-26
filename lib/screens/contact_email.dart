import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(loginScreen());
}

class loginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTP Verification',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedMode = 'email'; // 'email' or 'phone'
  String _verificationId = '';
  bool _isLoading = false;
  bool _otpSent = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Verification')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selection
            Text(
              'Choose verification method:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Email'),
                    value: 'email',
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value!;
                        _otpSent = false;
                        _controller.clear();
                        _otpController.clear();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Phone'),
                    value: 'phone',
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value!;
                        _otpSent = false;
                        _controller.clear();
                        _otpController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Input Field
            TextField(
              controller: _controller,
              keyboardType: _selectedMode == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
              decoration: InputDecoration(
                labelText: _selectedMode == 'email'
                    ? 'Enter Email Address'
                    : 'Enter Phone Number (+1234567890)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  _selectedMode == 'email' ? Icons.email : Icons.phone,
                ),
              ),
            ),

            SizedBox(height: 20),

            // OTP Input (shown after OTP is sent)
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Send/Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleButtonPress,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
            ),

            SizedBox(height: 20),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error')
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleButtonPress() {
    if (_otpSent) {
      _verifyOTP();
    } else {
      _sendOTP();
    }
  }

  Future<void> _sendOTP() async {
    if (_controller.text.trim().isEmpty) {
      _showMessage(
        'Please enter ${_selectedMode == 'email' ? 'email' : 'phone number'}',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (_selectedMode == 'email') {
        await _sendEmailOTP();
      } else {
        await _sendPhoneOTP();
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmailOTP() async {
    try {
      // For email OTP, we use Firebase's email link authentication
      // First, we need to create a temporary user or use email link

      // Method 1: Using ActionCodeSettings for email verification
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://yourapp.page.link/verify', // Your app's deep link
        handleCodeInApp: true,
        iOSBundleId: 'com.yourapp.bundle',
        androidPackageName: 'com.yourapp.package',
      );

      // Send verification email
      await _auth.sendSignInLinkToEmail(
        email: _controller.text.trim(),
        actionCodeSettings: actionCodeSettings,
      );

      setState(() {
        _otpSent = true;
      });
      _showMessage('Verification link sent to your email!');
    } catch (e) {
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  Future<void> _sendPhoneOTP() async {
    String phoneNumber = _controller.text.trim();

    // Ensure phone number has country code
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+1$phoneNumber'; // Default to US, modify as needed
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (on some Android devices)
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        _showMessage('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
        });
        _showMessage('OTP sent to your phone number!');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: Duration(seconds: 60),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      _showMessage('Please enter the OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (_selectedMode == 'email') {
        await _verifyEmailOTP();
      } else {
        await _verifyPhoneOTP();
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmailOTP() async {
    // For email verification, you would typically handle the deep link
    // This is a simplified version - in practice, you'd handle the link callback

    // Check if the email link is valid (this would come from deep link handling)
    String emailLink = _otpController.text
        .trim(); // In practice, this comes from the link

    if (_auth.isSignInWithEmailLink(emailLink)) {
      try {
        UserCredential result = await _auth.signInWithEmailLink(
          email: _controller.text.trim(),
          emailLink: emailLink,
        );

        _showMessage('Email verified successfully!');
        _navigateToHome(result.user);
      } catch (e) {
        throw Exception('Email verification failed: ${e.toString()}');
      }
    } else {
      throw Exception('Invalid verification link');
    }
  }

  Future<void> _verifyPhoneOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text.trim(),
    );

    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential result = await _auth.signInWithCredential(credential);
      _showMessage('Phone number verified successfully!');
      _navigateToHome(result.user);
    } catch (e) {
      throw Exception('Invalid OTP: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _navigateToHome(User? user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User? user;

  HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Verification Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (user != null) ...[
              if (user!.email != null) Text('Email: ${user!.email}'),
              if (user!.phoneNumber != null)
                Text('Phone: ${user!.phoneNumber}'),
            ],
          ],
        ),
      ),
    );
  }
}
