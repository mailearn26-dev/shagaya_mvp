import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(const ShagayaApp());
}

class ShagayaApp extends StatefulWidget {
  const ShagayaApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_ShagayaAppState>();
    state?.setLocale(locale);
  }

  @override
  State<ShagayaApp> createState() => _ShagayaAppState();
}

class _ShagayaAppState extends State<ShagayaApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Localization
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      home: const AuthGate(),
    );
  }
}
