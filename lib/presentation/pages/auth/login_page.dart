import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/core/helper/show_snackbar.dart';
import 'package:hiwar_marifa/presentation/pages/auth/email_verification_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/home_page.dart';
import 'package:hiwar_marifa/presentation/pages/auth/register_page.dart';
import 'package:hiwar_marifa/presentation/widgets/auth/custom_button.dart';
import 'package:hiwar_marifa/presentation/widgets/auth/custom_text_feild.dart';
import 'package:hiwar_marifa/provider/auth_provider.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static String id = "LoginPage";

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildRegisterLink(),
                ],
              ),
            ),
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
          'Login',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with your community',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
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
            'Login to your account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomFormTextFeild(
            hintText: 'Email',
            controller: _emailController,
            prefixIcon: Icons.email,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomFormTextFeild(
            hintText: 'Password',
            obscureText: _obscurePassword,
            controller: _passwordController,
            prefixIcon: Icons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade400,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                //-------------------============================
                ShowSnackBar.show(
                  context,
                  'Forgot password feature coming soon!',
                  Colors.blue,
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: kPrimaryColor, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              if (_emailController.text.isEmpty) {
                ShowSnackBar.show(
                  context,
                  'Please enter your email first',
                  Colors.orange,
                );
                return;
              }

              try {
                final user = _auth.currentUser;
                if (user != null && !user.emailVerified) {
                  await user.sendEmailVerification();
                  ShowSnackBar.show(
                    context,
                    'Verification email has been sent again.',
                    Colors.blue,
                  );
                } else {
                  try {
                    final userCredential = await _auth
                        .signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );

                    if (userCredential.user != null &&
                        !userCredential.user!.emailVerified) {
                      await userCredential.user!.sendEmailVerification();
                      ShowSnackBar.show(
                        context,
                        'Verification email has been sent.',
                        Colors.blue,
                      );
                    }

                    await _auth.signOut();
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      ShowSnackBar.show(
                        context,
                        'No account found with this email',
                        Colors.red,
                      );
                    } else if (e.code == 'wrong-password') {
                      await _handleResendVerificationForExistingUser();
                    } else {
                      rethrow;
                    }
                  }
                }
              } catch (e) {
                ShowSnackBar.show(
                  context,
                  'Failed to send verification email',
                  Colors.red,
                );
              }
            },
            child: Text(
              'Resend verification email?',
              style: TextStyle(color: kPrimaryColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Login',
            ontap: _handleLogin,
            backgroundColor: kPrimaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _handleResendVerificationForExistingUser() async {
    try {
      final tempUser = await _auth.createUserWithEmailAndPassword(
        email: 'temp_${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'temp_password_123',
      );

      await tempUser.user!.sendEmailVerification();

      await tempUser.user!.delete();

      ShowSnackBar.show(
        context,
        'Verification email has been sent.',
        Colors.blue,
      );
    } catch (e) {
      ShowSnackBar.show(
        context,
        'Please try logging in first to verify your account',
        Colors.orange,
      );
    }
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RegisterPage.id);
          },
          child: Text(
            'Register Now',
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<Authprovider>(context, listen: false);
      final authResult = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (authResult.user != null && !authResult.user!.emailVerified) {
        if (mounted) {
          ShowSnackBar.show(
            context,
            'Please verify your email before logging in.',
            Colors.orange,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ShowSnackBar.show(context, 'Login successful', Colors.green);
        Navigator.pushNamed(context, HomePage.id);
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar.show(context, e.toString(), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
