import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';  // Temporarily disabled
import 'package:star_sitters_core/star_sitters_core.dart';

import 'firebase_options.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init skipped or failed: $e\n$st');
  }

  try {
    await initStarSittersSupabase();
  } catch (e, st) {
    debugPrint('StarSitters init failed: $e\n$st');
  }

  // Sentry temporarily disabled
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Star Sitter Babysitter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
