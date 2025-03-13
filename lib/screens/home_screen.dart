import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

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
  String userName = 'User'; // Default fallback name
  String userEmail = '';
  String userPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() {
      userEmail = user.email ?? '';
      userPhotoUrl = user.photoURL ?? '';
    });

    try {
      await FirebaseFirestore.instance.enableNetwork(); // Ensure online
    } catch (e) {
      print("Error enabling Firestore network: $e");
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('name') && data['name'].toString().isNotEmpty) {
          setState(() {
            userName = data['name'];
          });
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            userName = user.displayName!;
          });
        } else {
          setState(() {
            userName = 'User';
          });
        }
      } else {
        // No Firestore doc, fallback to displayName or 'User'
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            userName = user.displayName!;
          });
        } else {
          setState(() {
            userName = 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Fallback to displayName or 'User'
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() {
          userName = user.displayName!;
        });
      } else {
        setState(() {
          userName = 'User';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'theme') {
                widget.toggleTheme();
              } else if (value == 'logout') {
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
              } else if (value == 'notifications') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No new notifications!')),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Text('Change Theme'),
              ),
              PopupMenuItem(
                value: 'notifications',
                child: Text('Notifications'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            icon: _buildProfilePicture(userPhotoUrl, 18, widget.isDarkMode),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture:
                  _buildProfilePicture(userPhotoUrl, 40, widget.isDarkMode),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Color(0xFF4B0082)
                    : Color(0xFF9370DB),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                      toggleTheme: widget.toggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.document_scanner),
              title: Text('Scan Your Report'),
              onTap: () {
                Navigator.pushNamed(context, '/scan_placeholder');
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
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
      ),
      body: Center(
        child: Text(
          'Welcome, $userName!',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chatbot');
        },
        child: Icon(Icons.chat),
      ),
    );
  }

  Widget _buildProfilePicture(
      String userPhotoUrl, double radius, bool isDarkMode) {
    Color backgroundColor =
        isDarkMode ? Color(0xFF4B0082) : Color(0xFF9370DB);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: userPhotoUrl.isNotEmpty
            ? Image.network(
                userPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/user_profile.jpg',
                    fit: BoxFit.cover,
                  );
                },
              )
            : Image.asset(
                'assets/images/user_profile.jpg',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
