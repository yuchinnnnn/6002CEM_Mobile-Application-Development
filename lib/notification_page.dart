import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  Future<void> markAsRead(String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(docId)
        .update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final docId = notifications[index].id;
              final title = data['title'] ?? 'No title';
              final body = data['body'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp).toDate();
              final read = data['read'] ?? false;

              return ListTile(
                leading: Icon(
                  read ? Icons.notifications_none : Icons.notifications_active,
                  color: read ? Colors.grey : Colors.orange,
                ),
                title: Text(title),
                subtitle: Text(body),
                trailing: Text(DateFormat('MMM d, HH:mm').format(timestamp)),
                tileColor: read ? Colors.white : Colors.orange.shade50,
                onTap: () => markAsRead(docId),
              );
            },
          );
        },
      ),
    );
  }
}
