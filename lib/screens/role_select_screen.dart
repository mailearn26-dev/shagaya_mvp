import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String role = 'consumer';

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.roleTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            RadioListTile(
              value: 'farmer',
              groupValue: role,
              onChanged: (v) => setState(() => role = v as String),
              title: Text(s.roleFarmer),
            ),
            RadioListTile(
              value: 'store',
              groupValue: role,
              onChanged: (v) => setState(() => role = v as String),
              title: Text(s.roleStore),
            ),
            RadioListTile(
              value: 'consumer',
              groupValue: role,
              onChanged: (v) => setState(() => role = v as String),
              title: Text(s.roleConsumer),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
                );
              },
              child: Text(s.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
