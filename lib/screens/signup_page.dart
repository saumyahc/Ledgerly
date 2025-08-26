import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../theme.dart';
import 'email_verification.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _passwordError;
  String? _confirmPasswordError;

  // Password requirements
  final List<_PasswordRequirement> _requirements = [
    _PasswordRequirement('At least 8 characters', (s) => s.length >= 8),
    _PasswordRequirement(
      'At least one uppercase letter',
      (s) => s.contains(RegExp(r'[A-Z]')),
    ),
    _PasswordRequirement(
      'At least one lowercase letter',
      (s) => s.contains(RegExp(r'[a-z]')),
    ),
    _PasswordRequirement(
      'At least one number',
      (s) => s.contains(RegExp(r'[0-9]')),
    ),
    _PasswordRequirement(
      'At least one special character (@#\$%^&*! etc)',
      (s) => s.contains(RegExp(r'[@#\$%\^&\*!]')),
    ),
  ];

  bool _isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  bool _isValidPhone(String input) {
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(input);
  }

  bool _isValidPassword(String password) {
    return _requirements.every((req) => req.check(password));
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

  String? _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!_isEmail(_emailController.text.trim())) {
      return 'Please enter a valid email address';
    }
    if (_phoneController.text.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!_isValidPhone(_phoneController.text.trim())) {
      return 'Please enter a valid phone number';
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Please enter a password');
      return 'Please enter a password';
    }
    if (!_isValidPassword(_passwordController.text)) {
      setState(() => _passwordError = 'Password does not meet requirements');
      return 'Password does not meet requirements';
    }
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      return 'Please confirm your password';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return 'Passwords do not match';
    }
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });
    return null;
  }

  Future<void> _handleSignUp() async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showErrorDialog(validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.signup),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        }),
      );
      setState(() => _isLoading = false);
      try {
        final data = jsonDecode(response.body);
        if (data['success'] == false &&
            (data['message']?.contains('already exists') ?? false)) {
          _showErrorDialog('User already signed up with this email.');
          return;
        }
      } catch (e) {
        // If response is not JSON, ignore and proceed
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EmailVerificationPage(initialEmail: _emailController.text.trim()),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to sign up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Create Account',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 26,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign up to get started',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                              labelText: 'Full Name',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.email,
                                color: AppColors.primary,
                              ),
                              labelText: 'Email Address',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.phone,
                                color: AppColors.primary,
                              ),
                              labelText: 'Phone Number',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Field with requirements info and live checklist
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock,
                                color: AppColors.primary,
                              ),
                              labelText: 'Password (at least 8 characters)',
                              errorText: _passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return _PasswordRequirementsDialog(
                                            requirements: _requirements,
                                            initialPassword:
                                                _passwordController.text,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _passwordError = null;
                              });
                            },
                          ),
                          if (_passwordError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                left: 12.0,
                              ),
                              child: Text(
                                _passwordError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                              ),
                              labelText: 'Confirm Password',
                              errorText: _confirmPasswordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _confirmPasswordError = null;
                              });
                            },
                          ),
                          if (_confirmPasswordError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                left: 12.0,
                              ),
                              child: Text(
                                _confirmPasswordError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Sign Up',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Login',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// Helper class for password requirements
class _PasswordRequirement {
  final String label;
  final bool Function(String) check;
  _PasswordRequirement(this.label, this.check);
}

// Password requirements dialog widget
class _PasswordRequirementsDialog extends StatefulWidget {
  final List<_PasswordRequirement> requirements;
  final String initialPassword;
  const _PasswordRequirementsDialog({
    required this.requirements,
    required this.initialPassword,
  });

  @override
  State<_PasswordRequirementsDialog> createState() =>
      _PasswordRequirementsDialogState();
}

class _PasswordRequirementsDialogState
    extends State<_PasswordRequirementsDialog> {
  late String _dialogPassword;

  @override
  void initState() {
    super.initState();
    _dialogPassword = widget.initialPassword;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Password Requirements'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _dialogPassword = val),
                controller: TextEditingController(text: _dialogPassword),
              ),
              SizedBox(height: 16),
              ...widget.requirements.map((req) {
                final met = req.check(_dialogPassword);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      met ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: met ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.label,
                        style: TextStyle(
                          color: met ? Colors.green : Colors.grey,
                          fontSize: 13,
                          decoration: met ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    );
  }
}
