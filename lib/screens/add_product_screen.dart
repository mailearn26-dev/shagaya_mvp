import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final fs = FirestoreService();

  final nameEn = TextEditingController();
  final nameAr = TextEditingController();
  final price = TextEditingController();
  final unit = TextEditingController(text: 'kg');
  final qty = TextEditingController();

  File? _selectedImage;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    nameEn.dispose();
    nameAr.dispose();
    price.dispose();
    unit.dispose();
    qty.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _publish() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final nameEnValue = nameEn.text.trim();
      final nameArValue = nameAr.text.trim();
      final unitValue = unit.text.trim();

      if (nameEnValue.isEmpty ||
          price.text.trim().isEmpty ||
          unitValue.isEmpty ||
          qty.text.trim().isEmpty) {
        setState(() => _error = 'Fill all fields.');
        return;
      }

      if (_selectedImage == null) {
        setState(() => _error = 'Please select an image.');
        return;
      }

      final parsedPrice = double.tryParse(price.text.trim());
      if (parsedPrice == null) {
        setState(() => _error = 'Price must be a number.');
        return;
      }

      final parsedQty = double.tryParse(qty.text.trim());
      if (parsedQty == null) {
        setState(() => _error = 'Quantity must be a number.');
        return;
      }

      final userDoc = await fs.userDoc(uid).get();
      final u = userDoc.data() ?? {};

      final productNameAr = nameArValue.isEmpty ? nameEnValue : nameArValue;

      // Create deterministic product id first (needed for Storage path)
      final productRef = fs.productsCol().doc();

      // 1) Create product with empty imageUrl
      await productRef.set({
        'farmerId': uid,
        'name': nameEnValue, // fallback/default
        'nameEn': nameEnValue,
        'nameAr': productNameAr,
        'price': parsedPrice,
        'unit': unitValue,
        'qty': parsedQty,
        'governorate': u['governorate'] ?? '',
        'area': u['area'] ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'imageUrl': '',
      });

      // 2) Upload image
      final imageUrl = await StorageService().uploadProductImage(
        file: _selectedImage!,
        productId: productRef.id,
      );

      // 3) Update product doc with final image URL
      await productRef.update({'imageUrl': imageUrl});

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
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
            TextField(
              controller: nameEn,
              decoration: const InputDecoration(
                labelText: 'Product Name (English)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameAr,
              decoration: const InputDecoration(
                labelText: 'Product Name (Arabic)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: price,
              decoration: InputDecoration(labelText: s.pricePerUnit),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unit,
              decoration: InputDecoration(labelText: s.unit),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qty,
              decoration: InputDecoration(labelText: s.quantity),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Image picker UI
            _selectedImage == null
                ? TextButton.icon(
                    onPressed: _submitting ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : _pickImage,
                        child: const Text('Change Image'),
                      ),
                    ],
                  ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _publish,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.publish),
            ),
          ],
        ),
      ),
    );
  }
}
