import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class RequestsInboxScreen extends StatefulWidget {
  const RequestsInboxScreen({super.key});

  @override
  State<RequestsInboxScreen> createState() => _RequestsInboxScreenState();
}

class _RequestsInboxScreenState extends State<RequestsInboxScreen> {
  final fs = FirestoreService();
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await fs.userDoc(uid).get();
    setState(() => role = (doc.data()?['role'] ?? 'consumer') as String);
  }

  Future<void> _setStatus(String requestId, String status) async {
    await fs.requestsCol().doc(requestId).update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final stream = (role == 'farmer')
        ? fs.requestsCol().where('farmerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots()
        : fs.requestsCol().where('buyerId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(s.inbox)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No requests.'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              final status = (m['status'] ?? 'PENDING') as String;

              return ListTile(
                title: Text('Product: ${m['productName']}'),
                subtitle: Text('Qty: ${m['qty'] ?? ''} • $status'),
                trailing: role == 'farmer'
                    ? Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: status == 'ACCEPTED' ? null : () => _setStatus(d.id, 'ACCEPTED'),
                            child: Text(s.accept),
                          ),
                          TextButton(
                            onPressed: status == 'REJECTED' ? null : () => _setStatus(d.id, 'REJECTED'),
                            child: Text(s.reject),
                          ),
                        ],
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
