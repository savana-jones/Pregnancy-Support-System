import 'package:flutter/material.dart';
import 'scan_report.dart'; // Make sure this matches your file structure

class ScanReportPlaceholderScreen extends StatelessWidget {
  const ScanReportPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Report'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera Icon at the top
            Icon(
              Icons.camera_alt,
              size: 100, // You can adjust the size as needed
              color: Colors.black,
            ),
            const SizedBox(height: 30),

            // Button with Black Text
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9370DB), // Light violet button
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ScanReportScreen()),
                );
              },
              child: const Text(
                "Scan your report",
                style: TextStyle(
                  color: Colors.black, // Black text color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
