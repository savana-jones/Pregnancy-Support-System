import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const SignupScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Signup Successful! Please verify your email before logging in.')),
        );

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup Failed! Please try again.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _isLoading = true);

    User? user = await _authService.signInWithGoogle();

    if (user != null) {
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Google Sign-Up Successful! Please verify your email.')),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-Up Failed!')),
      );
    }

    setState(() => _isLoading = false);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password.';
    if (value != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sign Up",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 10),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    SizedBox(height: 10),

                    // Confirm Password Input
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: _validateConfirmPassword,
                    ),
                    SizedBox(height: 20),

                    // Sign Up Button - full width
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Sign Up"),
                      ),
                    ),
                    SizedBox(height: 20),

                    Text("OR",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),

                    GestureDetector(
                      onTap: _isLoading ? null : _signupWithGoogle,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_logo.png', height: 24),
                            SizedBox(width: 10),
                            Text(
                              "Continue with Google",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, "/login"),
                      child: Text("Already have an account? Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
