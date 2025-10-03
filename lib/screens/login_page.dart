import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showDialog(String title, String message) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword() async {
    final emailForReset = TextEditingController(text: _emailController.text);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your email to receive a password reset link."),
              const SizedBox(height: 16),
              TextField(
                controller: emailForReset,
                decoration: const InputDecoration(hintText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailForReset.text.isEmpty) {
                  // FIX: Guard the context check
                  if (mounted) Navigator.of(context).pop();
                  _showDialog("Error", "Please enter an email address.");
                  return;
                }

                try {
                  await _auth.sendPasswordResetEmail(
                      email: emailForReset.text.trim());

                  if (mounted) Navigator.of(context).pop();
                  _showDialog("Success",
                      "If an account exists for that email, a password reset link has been sent.");
                } on FirebaseAuthException catch (e) {
                  if (mounted) Navigator.of(context).pop();
                  if (e.code == 'user-not-found' || e.code == 'invalid-email') {
                    _showDialog("Error",
                        "This email is not registered. Please sign up first.");
                  } else {
                    _showDialog("Error",
                        "Could not send reset link. Please try again.");
                  }
                }
              },
              child: const Text("Send Link"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address format is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'invalid-credential':
          message =
              "Incorrect email or password. Please try again or sign up if you don't have an account.";
          break;
        default:
          message = 'An unknown error occurred. Please try again.';
      }
      _showDialog("Login Error", message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to FuelGauge",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kSecondaryTextColor,
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(hintText: "Password"),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: kAccentColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kAccentColor,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
