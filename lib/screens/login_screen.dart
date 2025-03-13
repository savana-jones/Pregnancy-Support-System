import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password!')),
      );
      return;
    }

    User? user = await _authService.signIn(email, password);

    if (user != null) {
      await user.reload(); // Reload user to get updated info
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful!')),
        );
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
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email not verified. Please check your inbox.'),
            action: SnackBarAction(
              label: 'Resend',
              onPressed: _resendVerificationEmail,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed!')),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Verification email resent. Please check your inbox.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Unable to resend verification email. Please try logging in again.')),
        );
      }
    } catch (e) {
      print('Error resending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending verification email.')),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    User? user = await _authService.signInWithGoogle();

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Successful!')),
      );
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
        SnackBar(content: Text('Google Sign-In Failed!')),
      );
    }
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Email Input
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Password Input
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                      child: Text("Login"),
                    ),
                  ),
                  SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, "/reset"),
                    child: Text("Forgot Password?"),
                  ),
                  SizedBox(height: 20),

                  Text("OR",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),

                  GestureDetector(
                    onTap: _loginWithGoogle,
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
                    onPressed: () => Navigator.pushNamed(context, "/signup"),
                    child: Text("Don't have an account? Sign Up"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
