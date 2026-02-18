import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import 'add_product_screen.dart';
import 'requests_inbox_screen.dart';
import 'product_details_screen.dart';
import 'auth_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final fs = FirestoreService();
  String? role;
  String? governorate;
  String? area;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await fs.userDoc(uid).get();
    final data = doc.data() ?? {};
    setState(() {
      role = (data['role'] ?? 'consumer') as String;
      governorate = data['governorate'] as String?;
      area = data['area'] as String?;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canAddProduct = role == 'farmer';

    Query<Map<String, dynamic>> q = fs.productsCol().orderBy('createdAt', descending: true);

    if (governorate != null && governorate!.isNotEmpty) {
      q = q.where('governorate', isEqualTo: governorate);
    }
    if (area != null && area!.isNotEmpty) {
      q = q.where('area', isEqualTo: area);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.marketplace),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestsInboxScreen()),
            ),
            icon: const Icon(Icons.inbox_outlined),
            tooltip: s.inbox,
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: s.logout,
          ),
        ],
      ),
      floatingActionButton: canAddProduct
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(s.addProduct),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No listings yet.'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              return ListTile(
                title: Text((m['name'] ?? '') as String),
                subtitle: Text('${m['price'] ?? ''} / ${m['unit'] ?? ''} • Qty: ${m['qty'] ?? ''}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: d.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
