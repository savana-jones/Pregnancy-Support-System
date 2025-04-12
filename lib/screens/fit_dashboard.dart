import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fit/google_fit.dart';

class FitDashboardScreen extends StatefulWidget {
  final bool isDarkMode;

  const FitDashboardScreen({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _FitDashboardScreenState createState() => _FitDashboardScreenState();
}

class _FitDashboardScreenState extends State<FitDashboardScreen> {
  bool _isConnected = false;
  int _steps = 0;
  double _distance = 0.0;
  int _calories = 0;
  int _heartRate = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isConnected = await GoogleFit.checkPermissions();
      setState(() {
        _isConnected = isConnected;
        _isLoading = false;
      });
      
      if (isConnected) {
        _fetchFitData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to Google Fit: $e')),
      );
    }
  }

  Future<void> _connectToGoogleFit() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await GoogleFit.authorize();
      setState(() {
        _isConnected = success;
        _isLoading = false;
      });
      
      if (success) {
        _fetchFitData();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to Google Fit: $e')),
      );
    }
  }

  Future<void> _fetchFitData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Fetch steps
      final steps = await GoogleFit.getSteps(startOfDay, now);
      
      // Fetch distance
      final distance = await GoogleFit.getDistance(startOfDay, now);
      
      // Fetch calories
      final calories = await GoogleFit.getCalories(startOfDay, now);
      
      // Fetch heart rate (last reading)
      final heartRate = await GoogleFit.getHeartRate(now.subtract(Duration(hours: 1)), now);

      setState(() {
        _steps = steps ?? 0;
        _distance = distance ?? 0.0;
        _calories = calories ?? 0;
        _heartRate = heartRate?.last.value?.round() ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_isConnected)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Connect to Google Fit',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Connect to view your health data and track your pregnancy fitness',
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _connectToGoogleFit,
                              child: Text('Connect to Google Fit'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_isConnected) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.9,
                      padding: EdgeInsets.zero,
                      children: [
                        _buildMetricCard(
                          'Steps',
                          '$_steps',
                          Icons.directions_walk,
                          Colors.blue,
                        ),
                        _buildMetricCard(
                          'Distance',
                          '${_distance.toStringAsFixed(1)} km',
                          Icons.directions_run,
                          Colors.green,
                        ),
                        _buildMetricCard(
                          'Calories',
                          '$_calories',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _buildMetricCard(
                          'Heart Rate',
                          '$_heartRate bpm',
                          Icons.favorite,
                          Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pregnancy Health Tips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            _buildHealthTip('Aim for 8,000-10,000 steps daily for good circulation'),
                            _buildHealthTip('Keep your heart rate below 140 bpm during exercise'),
                            _buildHealthTip('Stay hydrated - drink at least 2L water daily'),
                            _buildHealthTip('Monitor your activity levels with your doctor'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHealthTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_services, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}