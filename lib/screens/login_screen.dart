import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';
import '../services/firestore_service.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isRegister = false;
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential cred;

      if (isRegister) {
        cred = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        // Create user document after successful registration
        final fs = FirestoreService();
        await fs.ensureUserDoc(uid: cred.user!.uid, email: email.text.trim(), role: widget.role);
        
        // Navigate to ProfileScreen after sign up
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(role: widget.role, uid: cred.user!.uid),
          ),
        );
      } else {
        cred = await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        // Navigate to AuthGate after successful login
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = 'CODE: ${e.code}\nMSG: ${e.message}');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? s.registerTitle : s.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: email, decoration: InputDecoration(labelText: s.email)),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              decoration: InputDecoration(labelText: s.password),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isRegister ? s.signUp : s.signIn),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => isRegister = !isRegister),
              child: Text(isRegister ? s.loginTitle : s.registerTitle),
            ),
          ],
        ),
      ),
    );
  }
}
