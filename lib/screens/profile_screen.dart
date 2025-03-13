import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  late final TextEditingController _emailController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: user?.email ?? '');
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _heightController.text = data['height']?.toString() ?? '';
      }
    } catch (e) {
      print("Error loading user data: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveUserData() async {
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
        'email': user!.email,
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: {
          'userName': _nameController.text.trim(),
        },
      );
    } catch (e) {
      print("Error saving user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = widget.isDarkMode ? Color(0xFF4B0082) : Color(0xFF9370DB);
    Color backgroundColor = widget.isDarkMode ? Colors.black : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6, color: Colors.white),
            onPressed: () => widget.toggleTheme(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // NO SCROLL
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor,
                        backgroundImage: user?.photoURL != null && user!.photoURL!.isNotEmpty
                            ? NetworkImage(user!.photoURL!)
                            : const AssetImage('assets/images/user_profile.jpg') as ImageProvider,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        label: "Name",
                        textColor: textColor,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        textColor: textColor,
                        primaryColor: primaryColor,
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _ageController,
                        label: "Age",
                        textColor: textColor,
                        primaryColor: primaryColor,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _weightController,
                        label: "Weight (kg)",
                        textColor: textColor,
                        primaryColor: primaryColor,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _heightController,
                        label: "Height (cm)",
                        textColor: textColor,
                        primaryColor: primaryColor,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveUserData,
                        icon: const Icon(Icons.save, color: Colors.white, size: 24),
                        label: const Text(
                          "SAVE & GO HOME",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(fontSize: 18),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.black, size: 24),
                        label: const Text(
                          "LOGOUT",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(fontSize: 18),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'App Version 1.0.0',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color textColor,
    required Color primaryColor,
    bool readOnly = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      style: TextStyle(color: textColor),
    );
  }
}
