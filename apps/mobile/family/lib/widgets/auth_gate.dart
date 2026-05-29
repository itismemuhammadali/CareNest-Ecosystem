import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home_screen.dart';
import '../screens/onboarding_flow.dart';

/// Routes by Supabase session and `users.role` (BACKEND.md §10).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final Stream<AuthState> _authStream;
  Future<Map<String, dynamic>?>? _userRowFuture;

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _session = auth.currentSession;
    _authStream = auth.onAuthStateChange;
    _authStream.listen((state) {
      if (state.session != null) {
        Future.microtask(_tryRegisterFcm);
        Future.microtask(systemConfig.load);
      }
    });
    if (_session != null) {
      Future.microtask(systemConfig.load);
    }
    _refreshUserRow();
  }

  void _refreshUserRow() {
    setState(() {
      _userRowFuture = ProfileRepository(Supabase.instance.client).currentUserRow();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tryRegisterFcm() async {
    if (kIsWeb) return; // FCM web requires VAPID key — not wired for local dev
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await DevicesRepository(client).registerFcmToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await DevicesRepository(client).registerFcmToken(
            token: newToken,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
        } catch (_) {}
      });
    } catch (e) {
      // F8: FCM failure must not be silent — log and surface to user
      debugPrint('FCM registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : _session;
        if (session == null) {
          return const OnboardingFlow();
        }

        final client = Supabase.instance.client;
        return FutureBuilder<Map<String, dynamic>?>(
          future: _userRowFuture,
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            // F7: Show retry on error instead of infinite spinner
            if (userSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load your profile. Check your connection.', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshUserRow,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final role = (userSnap.data?['role']?.toString().isNotEmpty == true)
                ? userSnap.data!['role'].toString()
                : client.auth.currentUser?.userMetadata?['role']?.toString();

            if (role != 'family') {
              final user = client.auth.currentUser;
              final provider = user?.appMetadata['provider']?.toString() ?? 'email';
              // During OAuth PKCE exchange the DB row may not be ready yet —
              // retry briefly instead of showing the wrong-role screen.
              if (userSnap.data == null && provider != 'email') {
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) _refreshUserRow();
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This build is for family accounts.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
