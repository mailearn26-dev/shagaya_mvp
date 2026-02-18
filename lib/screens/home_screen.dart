import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import 'add_product_screen.dart';
import 'requests_inbox_screen.dart';
import 'product_details_screen.dart';
import 'auth_gate.dart';
import '../main.dart';

const bool kDisableLocationFilterForMvp = true;

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
  debugPrint("HOME_SCREEN_BUILD: marketplace appbar actions active");

    final s = AppLocalizations.of(context)!;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canAddProduct = role == 'farmer';

    Query<Map<String, dynamic>> q = fs.productsCol();

    if (!kDisableLocationFilterForMvp) {
      if (governorate != null && governorate!.isNotEmpty) {
        q = q.where('governorate', isEqualTo: governorate);
      }
      if (area != null && area!.isNotEmpty) {
        q = q.where('area', isEqualTo: area);
      }
      q = q.orderBy('createdAt', descending: true);
    } else {
      // Commenting out orderBy due to potential index requirement
      // q = q.orderBy('createdAt', descending: true);
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    print('Current User - UID: $uid, Role: $role, Governorate: $governorate, Area: $area');
    print('Filters applied: ${!kDisableLocationFilterForMvp}');

    return Scaffold(
      appBar: AppBar(
        title: Text(s.marketplace),
        actions: [
          PopupMenuButton<String>(
  icon: const Icon(Icons.language),
  onSelected: (value) {
    if (value == 'en') {
      ShagayaApp.setLocale(context, const Locale('en'));
    } else if (value == 'ar') {
      ShagayaApp.setLocale(context, const Locale('ar'));
    }
  },
  itemBuilder: (context) => const [
    PopupMenuItem(value: 'en', child: Text('English')),
    PopupMenuItem(value: 'ar', child: Text('العربية')),
  ],
),

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              kDisableLocationFilterForMvp ? 'Filter: ALL' : 'Filter: governorate/area',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;

                print('Number of documents returned: ${docs.length}');

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
          ),
        ],
      ),
    );
  }
}
