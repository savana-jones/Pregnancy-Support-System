import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ResetPasswordScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<bool> _checkEmailExists(String email) async {
    try {
      var signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty; // If empty, email is not registered
    } catch (e) {
      return false;
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    String email = _emailController.text.trim();

    bool emailExists = await _checkEmailExists(email);
    if (!emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email not registered. Please sign up first.')),
      );
    } else {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent! Check your inbox.')),
      );
      Navigator.pop(context);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Enter your Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        'Send Reset Email',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
