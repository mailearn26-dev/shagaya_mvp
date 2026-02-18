import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'role_select_screen.dart';
import 'home_screen.dart';
import '../services/firestore_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const RoleSelectScreen();

        final fs = FirestoreService();
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: fs.userDoc(user.uid).get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final docExists = docSnap.hasData && docSnap.data!.exists;
            print('AuthGate: userDoc exists = $docExists');

            if (!docExists) {
              return const RoleSelectScreen();
            } else {
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
