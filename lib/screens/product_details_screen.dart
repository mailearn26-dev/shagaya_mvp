import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final fs = FirestoreService();
  final qty = TextEditingController();
  final notes = TextEditingController();
  bool sending = false;

  Future<void> _sendRequest(Map<String, dynamic> product) async {
    setState(() => sending = true);
    try {
      final buyerId = FirebaseAuth.instance.currentUser!.uid;
      print('Sending request to farmerId: ${product['farmerId']}');
      await fs.requestsCol().add({
        'productId': widget.productId,
        'farmerId': product['farmerId'] ?? product['uid'],
        'buyerId': buyerId,
        'qty': qty.text.trim(),
        'notes': notes.text.trim(),
        'status': 'PENDING',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent.')));
    } finally {
      setState(() => sending = false);
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final normalized = phone.replaceAll('+', '').replaceAll(' ', '');
    final url = Uri.parse('https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final url = Uri.parse('tel:$phone');
    await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: fs.productsCol().doc(widget.productId).get(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final product = snap.data!.data() ?? {};

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: fs.userDoc(product['farmerId']).get(),
            builder: (context, farmerSnap) {
              if (!farmerSnap.hasData) return const Center(child: CircularProgressIndicator());
              final farmer = farmerSnap.data!.data() ?? {};
              final farmerPhone = (farmer['phone'] ?? '') as String;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text((product['name'] ?? '') as String,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('${product['price']} / ${product['unit']}'),
                    const SizedBox(height: 8),
                    Text('Qty: ${product['qty']}'),
                    const Divider(height: 24),

                    Text(s.request, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(controller: qty, decoration: InputDecoration(labelText: s.requestQty)),
                    const SizedBox(height: 8),
                    TextField(controller: notes, decoration: InputDecoration(labelText: s.requestNotes)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: sending ? null : () => _sendRequest(product),
                      child: sending
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(s.sendRequest),
                    ),

                    const Divider(height: 24),
                    Text(s.contact, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: farmerPhone.isEmpty
                                ? null
                                : () => _launchWhatsApp(
                                      farmerPhone,
                                      'Hello, I am interested in ${product['name']}. Qty: ${qty.text.trim().isEmpty ? 'N/A' : qty.text.trim()}',
                                    ),
                            icon: const Icon(Icons.chat),
                            label: Text(s.whatsapp),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: farmerPhone.isEmpty ? null : () => _call(farmerPhone),
                            icon: const Icon(Icons.call),
                            label: Text(s.call),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
