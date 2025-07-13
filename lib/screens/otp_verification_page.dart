// otp_verification_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import '../theme.dart';

class OTPVerificationPage extends StatelessWidget {
  const OTPVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Glass3DCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Verify OTP',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the OTP sent to your email',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                          labelText: 'OTP',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Neumorphic3DButton(
                          child: Text('Verify', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Didn't receive the OTP? Resend",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
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
