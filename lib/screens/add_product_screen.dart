import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final fs = FirestoreService();
  final name = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController(text: 'kg');
  final qty = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> _publish() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await fs.userDoc(uid).get();
      final u = userDoc.data() ?? {};

      if (name.text.trim().isEmpty ||
          price.text.trim().isEmpty ||
          unit.text.trim().isEmpty ||
          qty.text.trim().isEmpty) {
        setState(() => error = 'Fill all fields.');
        return;
      }

      await fs.productsCol().add({
        'farmerId': uid,
        'name': name.text.trim(),
        'price': double.tryParse(price.text.trim()) ?? price.text.trim(),
        'unit': unit.text.trim(),
        'qty': double.tryParse(qty.text.trim()) ?? qty.text.trim(),
        'governorate': u['governorate'] ?? '',
        'area': u['area'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.addProduct)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: s.productName)),
            const SizedBox(height: 12),
            TextField(controller: price, decoration: InputDecoration(labelText: s.pricePerUnit), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: unit, decoration: InputDecoration(labelText: s.unit)),
            const SizedBox(height: 12),
            TextField(controller: qty, decoration: InputDecoration(labelText: s.quantity), keyboardType: TextInputType.number),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _publish,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.publish),
            ),
          ],
        ),
      ),
    );
  }
}
