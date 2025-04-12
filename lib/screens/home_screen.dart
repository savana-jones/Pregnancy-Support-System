import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'login_screen.dart';

// Add this BreathingExerciseWidget class before your HomeScreen class
class BreathingExerciseWidget extends StatefulWidget {
  final bool isDarkMode;

  const BreathingExerciseWidget({Key? key, required this.isDarkMode})
      : super(key: key);

  @override
  _BreathingExerciseWidgetState createState() =>
      _BreathingExerciseWidgetState();
}

class _BreathingExerciseWidgetState extends State<BreathingExerciseWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _currentInstruction = 'Ready to begin';
  int _currentStep = 0;
  bool _isRunning = false;
  final List<String> _instructions = [
    'Breathe In',
    'Hold',
    'Breathe Out',
    'Rest'
  ];
  final List<int> _durations = [4, 4, 6, 2]; // in seconds

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _currentStep = 0;
      _currentInstruction = _instructions[_currentStep];
      _runStep();
    });
  }

  void _runStep() {
    _controller.duration = Duration(seconds: _durations[_currentStep]);
    _controller.reset();
    _controller.forward().then((_) {
      if (_currentStep < _instructions.length - 1) {
        setState(() {
          _currentStep++;
          _currentInstruction = _instructions[_currentStep];
        });
        _runStep();
      } else {
        setState(() {
          _currentStep = 0;
          _currentInstruction = 'Completed one cycle';
          _isRunning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  double size;
                  Color color;

                  if (_currentStep == 0) {
                    // Breathe in
                    size = 50 + (_animation.value * 100);
                    color =
                        Colors.blue.withOpacity(0.5 + (_animation.value * 0.5));
                  } else if (_currentStep == 2) {
                    // Breathe out
                    size = 150 - (_animation.value * 100);
                    color = Colors.green
                        .withOpacity(1.0 - (_animation.value * 0.5));
                  } else {
                    // Hold or rest
                    size = 150;
                    color = _currentStep == 1
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.5);
                  }

                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              Text(
                _currentInstruction,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Positioned(
                bottom: 10,
                child: Text(
                  _isRunning
                      ? '${_durations[_currentStep] - (_animation.value * _durations[_currentStep]).floor()}s'
                      : '',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isRunning ? null : _startExercise,
          child:
              Text(_isRunning ? 'Exercise in progress...' : 'Start Exercise'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor:
                _isRunning ? Colors.grey : Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = 'User';
  String userEmail = '';
  String userPhotoUrl = '';
  String randomQuote = '';

  List<String> quotes = [
    "You're doing an amazing job growing a human!",
    "Every kick is a reminder of the love you're creating.",
    "Your body is doing something miraculous—be kind to it.",
    "Pregnancy is a journey—enjoy each moment.",
    "You are stronger than you think, mama!",
    "The best is yet to come... your little one!",
    "Your baby already loves the sound of your heartbeat.",
    "Take time to rest—you're building a person!",
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _generateRandomQuote();
  }

  // ADDED TO REFRESH DATA WHEN RETURNING FROM PROFILE
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchUserData();
    }
  }

  void _generateRandomQuote() {
    final random = DateTime.now().millisecond % quotes.length;
    setState(() {
      randomQuote = quotes[random];
    });
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      userEmail = user.email ?? '';
      userPhotoUrl = user.photoURL ?? '';
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? user.displayName ?? 'User';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<Map<String, String>> _getPregnancyInfo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final now = DateTime.now();

      final dueDate = data['dueDate']?.toDate();
      final lastMenstrualPeriod = data['lastMenstrualPeriod']?.toDate();
      final nextCheckupDate = data['checkupDate']?.toDate();
      final doctorName = data['doctorName'] ?? 'Your Doctor';
      final storedTrimester = data['trimester']?.toString();

      String currentWeek = 'Not specified';
      String trimester = storedTrimester ?? 'Not specified';
      String daysUntilDue = 'Not specified';

      if (dueDate != null) {
        // Calculate days remaining (can be negative if past due date)
        final days = dueDate.difference(now).inDays;
        daysUntilDue = '$days days';
        
        // Calculate current week (1-40)
        final totalDays = 280; // Standard 40-week pregnancy
        final elapsedDays = totalDays - days;
        final weeks = (elapsedDays / 7).floor();
        currentWeek = '$weeks weeks';

        // Calculate trimester based on current week
        trimester = weeks < 13
            ? '1'
            : weeks < 27
                ? '2'
                : '3';
      } else if (lastMenstrualPeriod != null) {
        // Calculate from LMP if due date not available
        final daysSinceLMP = now.difference(lastMenstrualPeriod).inDays;
        final weeks = (daysSinceLMP / 7).floor();
        currentWeek = '$weeks weeks';
        
        // Calculate days until due (assuming 280 day pregnancy)
        final estimatedDueDate = lastMenstrualPeriod.add(Duration(days: 280));
        final days = estimatedDueDate.difference(now).inDays;
        daysUntilDue = '$days days';
        
        trimester = weeks < 13
            ? '1'
            : weeks < 27
                ? '2'
                : '3';
      }

      // Format next appointment
      String nextAppointment = '';
      if (nextCheckupDate != null) {
        nextAppointment =
            '${DateFormat('MMM dd, yyyy').format(nextCheckupDate)}|$doctorName';
      } else {
        nextAppointment = 'No upcoming appointment|';
      }
      
      return {
        'currentWeek': currentWeek,
        'trimester': 'Trimester $trimester',
        'daysUntilDue': daysUntilDue,
        'nextAppointment': nextAppointment,
      };
    }
  } catch (e) {
    print('Error fetching pregnancy info: $e');
  }

  return {
    'currentWeek': 'Not specified',
    'trimester': 'Not specified',
    'daysUntilDue': 'Not specified',
    'nextAppointment': 'No upcoming appointment|',
  };
}

// Replace your _buildInfoRow with this:
  Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: value.contains('|') && label == 'Next Doctor Visit:'
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (value.split('|')[0].isNotEmpty)
                      Text(
                        value.split('|')[0],
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.end,
                      ),
                    if (value.split('|').length > 1 && value.split('|')[1].isNotEmpty)
                      Text(
                        value.split('|')[1],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.end,
                      ),
                  ],
                )
              : Text(
                  value,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.end,
                ),
        ),
      ],
    ),
  );
}

  Widget _buildPregnancyCard() {
  return FutureBuilder<Map<String, String>>(
    future: _getPregnancyInfo(),
    builder: (context, snapshot) {
      final pregnancyInfo = snapshot.data ??
          {
            'currentWeek': 'Loading...',
            'trimester': 'Loading...',
            'daysUntilDue': 'Loading...',
            'nextAppointment': 'Loading...',
          };

      return Card(
        elevation: 4,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: double.infinity,
            minHeight: 200, // Set a minimum height
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pregnancy Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow('Current Week:', pregnancyInfo['currentWeek']!),
                _buildInfoRow('Trimester:', pregnancyInfo['trimester']!),
                _buildInfoRow('Days Until Due:', pregnancyInfo['daysUntilDue']!),
                _buildInfoRow('Next Doctor Visit:', pregnancyInfo['nextAppointment']!),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildQuoteCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.favorite, color: Colors.pink, size: 40),
                SizedBox(height: 16),
                Text(
                  randomQuote,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _generateRandomQuote,
                  child: Text('New Quote'),
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
      ),
    );
  }

  Widget _buildRelaxationCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Breathing Exercise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Follow the breathing pattern to relax:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            BreathingExerciseWidget(isDarkMode: widget.isDarkMode),
            SizedBox(height: 16),
            Text(
              '4-4-6 Breathing Technique:\n'
              '1. Breathe in for 4 seconds\n'
              '2. Hold for 4 seconds\n'
              '3. Exhale for 6 seconds\n',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'theme') widget.toggleTheme();
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      toggleTheme: widget.toggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                );
              }
              if (value == 'notifications') {
                Navigator.pushNamed(context, '/notifications');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'theme', child: Text('Change Theme')),
              PopupMenuItem(
                  value: 'notifications', child: Text('Notifications')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            icon: CircleAvatar(
              radius: 18,
              backgroundColor:
                  widget.isDarkMode ? Color(0xFF4B0082) : Color(0xFF9370DB),
              child: userPhotoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(userPhotoUrl, fit: BoxFit.cover))
                  : Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Welcome back, $userName!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
            _buildPregnancyCard(),
            _buildQuoteCard(),
            _buildRelaxationCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
        tooltip: 'Chatbot',
        child: Icon(Icons.chat),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor:
                  widget.isDarkMode ? Color(0xFF4B0082) : Color(0xFF9370DB),
              child: userPhotoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(userPhotoUrl, fit: BoxFit.cover))
                  : Icon(Icons.person, color: Colors.white),
            ),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Color(0xFF4B0082) : Color(0xFF9370DB),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.document_scanner),
            title: Text('Scan Your Report'),
            onTap: () => Navigator.pushNamed(context, '/scan_placeholder'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          Spacer(),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    toggleTheme: widget.toggleTheme,
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
