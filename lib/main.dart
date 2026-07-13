import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: FeeApp()));
}

class FeeApp extends StatelessWidget {
  const FeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priyadarsini Fee App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
