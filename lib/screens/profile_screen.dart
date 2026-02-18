import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  final String uid;

  const ProfileScreen({super.key, required this.role, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final governorate = TextEditingController();
  final area = TextEditingController();

  bool loading = false;
  double? lat;
  double? lng;
  String? error;

  Future<void> _getGps() async {
    setState(() => error = null);

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      setState(() => error = 'Location services are disabled.');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();

    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      setState(() => error = 'Location permission denied.');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    setState(() {
      lat = pos.latitude;
      lng = pos.longitude;
    });
  }

  Future<void> _save() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (name.text.trim().isEmpty ||
          phone.text.trim().isEmpty ||
          governorate.text.trim().isEmpty ||
          area.text.trim().isEmpty) {
        setState(() => error = 'Please fill all required fields.');
        return;
      }

      final fs = FirestoreService();
      await fs.userDoc(widget.uid).set({
        'role': widget.role,
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'governorate': governorate.text.trim(),
        'area': area.text.trim(),
        'lat': lat,
        'lng': lng,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
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
      appBar: AppBar(title: Text(s.profileTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: s.name)),
            const SizedBox(height: 12),
            TextField(controller: phone, decoration: InputDecoration(labelText: s.phone)),
            const SizedBox(height: 12),
            TextField(controller: governorate, decoration: InputDecoration(labelText: s.governorate)),
            const SizedBox(height: 12),
            TextField(controller: area, decoration: InputDecoration(labelText: s.area)),
            const SizedBox(height: 12),

            Text(s.gpsRecommended),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(onPressed: _getGps, child: Text(s.enableGps)),
                const SizedBox(width: 12),
                if (lat != null && lng != null) Expanded(child: Text('GPS: $lat, $lng')),
              ],
            ),

            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(s.save),
            ),
          ],
        ),
      ),
    );
  }
}
