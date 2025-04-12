import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
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
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // Controllers for all text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _sleepHoursController = TextEditingController();
  final TextEditingController _waterIntakeController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactNumberController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorContactController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _stepsGoalController = TextEditingController();
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Dropdown selections
  String? _pregnancyStatus;
  String? _trimester;
  String? _bloodGroup;
  String? _activityLevel;
  String? _nutritionPreference;
  bool _smokingAlcohol = false;

  DateTime? _checkupDate;
  DateTime? _nextCheckupDate;
  DateTime? _dueDate;
  DateTime? _lastMenstrualPeriod;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _nameController.text = data['name']?.toString() ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _weightController.text = data['weight']?.toString() ?? '';
          _heightController.text = data['height']?.toString() ?? '';
          _pregnancyStatus = data['pregnancyStatus']?.toString();
          _trimester = data['trimester']?.toString();
          _bloodGroup = data['bloodGroup']?.toString();
          _medicalConditionsController.text = data['medicalConditions']?.toString() ?? '';
          _allergiesController.text = data['allergies']?.toString() ?? '';
          _activityLevel = data['activityLevel']?.toString();
          _sleepHoursController.text = data['sleepHours']?.toString() ?? '';
          _waterIntakeController.text = data['waterIntakeGoal']?.toString() ?? '';
          _nutritionPreference = data['nutritionPreference']?.toString();
          _emergencyContactNameController.text = data['emergencyContactName']?.toString() ?? '';
          _emergencyContactNumberController.text = data['emergencyContactNumber']?.toString() ?? '';
          _doctorNameController.text = data['doctorName']?.toString() ?? '';
          _doctorContactController.text = data['doctorContact']?.toString() ?? '';
          _medicationsController.text = data['medications']?.toString() ?? '';
          _smokingAlcohol = data['smokingAlcohol'] ?? false;
          _stepsGoalController.text = data['stepsGoal']?.toString() ?? '';
          _partnerNameController.text = data['partnerName']?.toString() ?? '';
          _addressController.text = data['address']?.toString() ?? '';
          _dueDate = data['dueDate']?.toDate();
          _lastMenstrualPeriod = data['lastMenstrualPeriod']?.toDate();
          _checkupDate = data['checkupDate']?.toDate();
          _nextCheckupDate = _checkupDate?.add(const Duration(days: 14));
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update next checkup date
      _nextCheckupDate = _checkupDate?.add(const Duration(days: 14));

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'height': double.tryParse(_heightController.text.trim()) ?? 0.0,
        'pregnancyStatus': _pregnancyStatus,
        'trimester': _trimester,
        'dueDate': _dueDate,
        'bloodGroup': _bloodGroup,
        'medicalConditions': _medicalConditionsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'activityLevel': _activityLevel,
        'sleepHours': int.tryParse(_sleepHoursController.text.trim()) ?? 0,
        'waterIntakeGoal': double.tryParse(_waterIntakeController.text.trim()) ?? 0.0,
        'nutritionPreference': _nutritionPreference,
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'emergencyContactNumber': _emergencyContactNumberController.text.trim(),
        'doctorName': _doctorNameController.text.trim(),
        'doctorContact': _doctorContactController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'smokingAlcohol': _smokingAlcohol,
        'stepsGoal': int.tryParse(_stepsGoalController.text.trim()) ?? 0,
        'lastMenstrualPeriod': _lastMenstrualPeriod,
        'partnerName': _partnerNameController.text.trim(),
        'address': _addressController.text.trim(),
        'checkupDate': _checkupDate,
        'nextCheckupDate': _nextCheckupDate,
      }, SetOptions(merge: true));

      // Notifications will be handled automatically by the NotificationService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving profile')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime? initialDate, 
      Function(DateTime) onDateSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
            tooltip: "Switch Theme",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Name'),
                    _buildTextField(_ageController, 'Age',
                        keyboardType: TextInputType.number),
                    _buildTextField(_weightController, 'Weight (kg)',
                        keyboardType: TextInputType.number),
                    _buildTextField(_heightController, 'Height (cm)',
                        keyboardType: TextInputType.number),
                    _buildDropdown('Pregnancy Status', _pregnancyStatus,
                        ['Pregnant', 'Not Pregnant'], (val) {
                      setState(() => _pregnancyStatus = val);
                    }),
                    if (_pregnancyStatus == 'Pregnant')
                      _buildDropdown(
                          'Trimester', _trimester, ['1st', '2nd', '3rd'],
                          (val) {
                        setState(() => _trimester = val);
                      }),
                    _buildDateField('Checkup Date', _checkupDate, (picked) {
                      setState(() {
                        _checkupDate = picked;
                        _nextCheckupDate = picked.add(const Duration(days: 14));
                      });
                    }),
                    if (_nextCheckupDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Next Checkup Date: ${DateFormat('MMM dd, yyyy').format(_nextCheckupDate!)}',
                          style: const TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    _buildDateField('Due Date', _dueDate,
                        (picked) => setState(() => _dueDate = picked)),
                    _buildDropdown(
                        'Blood Group',
                        _bloodGroup,
                        ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                        (val) => setState(() => _bloodGroup = val)),
                    _buildTextField(
                        _medicalConditionsController, 'Medical Conditions'),
                    _buildTextField(
                        _allergiesController, 'Allergies (Optional)'),
                    _buildDropdown(
                        'Activity Level',
                        _activityLevel,
                        ['Low', 'Moderate', 'High'],
                        (val) => setState(() => _activityLevel = val)),
                    _buildTextField(
                        _sleepHoursController, 'Sleep Hours (per day)',
                        keyboardType: TextInputType.number),
                    _buildTextField(_waterIntakeController,
                        'Water Intake Goal (litres/day)',
                        keyboardType: TextInputType.number),
                    _buildDropdown(
                        'Nutrition Preference',
                        _nutritionPreference,
                        ['Vegetarian', 'Non-Vegetarian', 'Vegan'],
                        (val) => setState(() => _nutritionPreference = val)),
                    _buildTextField(_emergencyContactNameController,
                        'Emergency Contact Name'),
                    _buildTextField(_emergencyContactNumberController,
                        'Emergency Contact Number',
                        keyboardType: TextInputType.phone),
                    _buildTextField(
                        _doctorNameController, 'Doctor/Consultant Name'),
                    _buildTextField(
                        _doctorContactController, 'Doctor/Consultant Contact',
                        keyboardType: TextInputType.phone),
                    _buildTextField(
                        _medicationsController, 'Medications (Optional)'),
                    SwitchListTile(
                      title: const Text('Smoking/Alcohol Use'),
                      value: _smokingAlcohol,
                      onChanged: (val) => setState(() => _smokingAlcohol = val),
                    ),
                    _buildTextField(
                        _stepsGoalController, 'Steps Goal (per day)',
                        keyboardType: TextInputType.number),
                    _buildDateField(
                        'Last Menstrual Period',
                        _lastMenstrualPeriod,
                        (picked) =>
                            setState(() => _lastMenstrualPeriod = picked)),
                    _buildTextField(_partnerNameController,
                        'Partner/Support Person Name (Optional)'),
                    _buildTextField(_addressController, 'Address (Optional)'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                    const SizedBox(height: 10),
                    const Text('App Version 1.0.0',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (labelText.contains('Optional')) return null;
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (val) {
          if (val == null || val.isEmpty) return 'Please select $label';
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, Function(DateTime) onDateSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _pickDate(context, date, onDateSelected),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(date == null
              ? 'Select Date'
              : DateFormat('MMM dd, yyyy').format(date)),
        ),
      ),
    );
  }
}