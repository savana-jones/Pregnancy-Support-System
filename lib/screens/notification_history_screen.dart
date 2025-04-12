// notification_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _clearHistory(context),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notification_history')
            .orderBy('time', descending: true)
            .limit(12)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notifications = snapshot.data!.docs;
          
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          // Group by date
          final grouped = _groupByDate(notifications);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final date = grouped.keys.elementAt(index);
              final items = grouped[date]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  ...items.map((notif) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        Icons.notifications,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(notif['title']),
                      subtitle: Text(notif['body']),
                      trailing: Text(
                        DateFormat('h:mm a').format(DateTime.parse(notif['time']).toLocal()),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(List<QueryDocumentSnapshot> notifications) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final doc in notifications) {
      final data = doc.data() as Map<String, dynamic>;
      final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(data['time']).toLocal());
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(data);
    }
    
    return grouped;
  }

  Future<void> _clearHistory(BuildContext context) async {
    try {
      final snapshot = await _firestore.collection('notification_history').get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification history cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear history')),
      );
    }
  }
}