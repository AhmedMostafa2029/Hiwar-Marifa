import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/core/helper/show_snackbar.dart';
import 'package:hiwar_marifa/presentation/pages/home/home_page.dart';
import 'package:hiwar_marifa/presentation/widgets/auth/custom_button.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String password;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.password,
  });

  static const String id = 'EmailVerificationPage';

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isEmailVerified = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _verificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        setState(() {
          _isEmailVerified = true;
        });

        await _firestore.collection(kUsersCollection).doc(user.uid).update({
          'emailVerified': true,
          'lastLogin': FieldValue.serverTimestamp(),
        });

        _verificationTimer?.cancel();

        if (mounted) {
          Navigator.pushReplacementNamed(context, HomePage.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(
          context,
          'Error checking verification status',
          Colors.red,
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        ShowSnackBar.show(
          context,
          'Verification email sent successfully',
          Colors.green,
        );
      } else {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        await userCredential.user!.sendEmailVerification();
        ShowSnackBar.show(
          context,
          'Verification email sent successfully',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(
          context,
          'Failed to send verification email',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildVerificationCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(kLogo),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verify Your Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your inbox for verification link',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email Verification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'We have sent a verification email to:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please check your inbox and click on the verification link to activate your account.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Didn\'t receive the email?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Resend Verification Email',
            ontap: _resendVerificationEmail,
            backgroundColor: kPrimaryColor,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          const Text(
            'Checking verification status every 5 seconds...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
