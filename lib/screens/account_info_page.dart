import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ledgerly/theme.dart';

class AccountInfoPage extends StatefulWidget {
  @override
  _AccountInfoPageState createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String dob = '';
  String gender = '';
  String phone = '';
  String email = '';
  
  // Validation state variables
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          body: Stack(
            children: [
              // Subtle background circles for depth
              Positioned(
                top: -60,
                left: -60,
                child: _buildBackgroundCircle(180, [Color(0xFF00d4ff).withOpacity(0.2), Color(0xFF16213e).withOpacity(0.1)]),
              ),
              Positioned(
                bottom: -40,
                right: -40,
                child: _buildBackgroundCircle(120, [Color(0xFF0f3460).withOpacity(0.15), Color(0xFF00d4ff).withOpacity(0.1)]),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Gradient Avatar with 3D effect
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF00d4ff), Color(0xFF0f3460)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 64, color: Color(0xFF1a1a2e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update your details',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Glassmorphism Card with 3D shadow
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 32,
                                    offset: Offset(0, 16),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Form(
                                key: _formKey,
                                child: ListView(
                                  children: [
                                    _buildEditableField(
                                      icon: Icons.person,
                                      label: 'First Name',
                                      initialValue: firstName,
                                      onChanged: (val) => setState(() => firstName = val),
                                      gradientIcon: true,
                                      errorMessage: _firstNameError,
                                    ),
                                    _buildEditableField(
                                      icon: Icons.person_outline,
                                      label: 'Last Name',
                                      initialValue: lastName,
                                      onChanged: (val) => setState(() => lastName = val),
                                      gradientIcon: true,
                                      errorMessage: _lastNameError,
                                    ),
                                    _buildEditableField(
                                      icon: Icons.cake,
                                      label: 'Date of Birth',
                                      initialValue: dob,
                                      onChanged: (val) => setState(() => dob = val),
                                      gradientIcon: true,
                                    ),
                                    _buildEditableField(
                                      icon: Icons.wc,
                                      label: 'Gender',
                                      initialValue: gender,
                                      onChanged: (val) => setState(() => gender = val),
                                      gradientIcon: true,
                                    ),
                                    _buildEditableField(
                                      icon: Icons.phone,
                                      label: 'Phone Number',
                                      initialValue: phone,
                                      keyboardType: TextInputType.phone,
                                      onChanged: (val) => setState(() => phone = val),
                                      gradientIcon: true,
                                      errorMessage: _phoneError,
                                    ),
                                    _buildEditableField(
                                      icon: Icons.email,
                                      label: 'Email',
                                      initialValue: email,
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (val) => setState(() => email = val),
                                      gradientIcon: true,
                                      errorMessage: _emailError,
                                    ),
                                    const SizedBox(height: 24),
                                    // Gradient Button with shadow
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF00d4ff).withOpacity(0.25),
                                            blurRadius: 16,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ).copyWith(
                                          elevation: MaterialStateProperty.all(0),
                                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                                        ),
                                        onPressed: () {
                                          if (_validateForm()) {
                                            // Save logic here
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Information saved!')),
                                            );
                                          }
                                        },
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF00d4ff), Color(0xFF0f3460)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            constraints: BoxConstraints(minHeight: 48),
                                            child: const Text(
                                              'Save',
                                              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required String initialValue,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
    bool gradientIcon = false,
    String? errorMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            gradientIcon
                ? ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        colors: [Color(0xFF00d4ff), Color(0xFF0f3460)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Icon(icon, color: Colors.white, size: 24),
                  )
                : Icon(icon, color: Color(0xFF1a1a2e)),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: initialValue,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: errorMessage != null ? Colors.red : Color(0xFF1a1a2e),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: errorMessage != null ? Colors.red : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: errorMessage != null ? Colors.red : Color(0xFF1a1a2e),
                    ),
                  ),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 36.0),
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  bool _validateForm() {
    bool isValid = true;
    
    // Reset all errors
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _phoneError = null;
    });
    
    // First Name validation
    if (firstName.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      isValid = false;
    }
    
    // Last Name validation
    if (lastName.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      isValid = false;
    }
    
    // Email validation
    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      isValid = false;
    }
    
    // Phone validation
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Phone number is required');
      isValid = false;
    }
    
    return isValid;
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Widget _buildBackgroundCircle(double size, List<Color> colors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
} 