import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home_screen.dart';
import '../screens/onboarding_flow.dart';
import '../screens/profile_under_review_screen.dart';
import '../screens/sign_in_screen.dart';

/// Routes by Supabase session, sitter role, and `sitter_profiles.is_active` (BACKEND.md §10 / §17).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final Stream<AuthState> _authStream;
  Timer? _idleTimer;
  static const _idleTimeout = Duration(minutes: 15);
  Future<Map<String, dynamic>?>? _userRowFuture;

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (Supabase.instance.client.auth.currentSession == null) return;
    _idleTimer = Timer(_idleTimeout, () {
      Supabase.instance.client.auth.signOut();
    });
  }

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
        _resetIdleTimer();
      } else {
        _idleTimer?.cancel();
      }
    });
    if (_session != null) {
      _resetIdleTimer();
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
    _idleTimer?.cancel();
    super.dispose();
  }

  Future<void> _tryRegisterFcm() async {
    if (kIsWeb) return; // FCM web requires VAPID key — not wired for local dev
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: notification permission denied by user');
        return;
      }
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
      debugPrint('FCM registration failed: $e');
    }
  }

  Future<bool> _claimSitterRole() async {
    try {
      await Supabase.instance.client.rpc('claim_sitter_role');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  Widget _wrongRoleScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'This build is for babysitter accounts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Supabase.instance.client.auth.signOut(),
                child: const Text('Sign out & switch account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleTimer(),
      child: StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : _session;
        if (session == null) {
          // Check if onboarding was already seen
          return FutureBuilder<bool>(
            future: _hasSeenOnboarding(),
            builder: (context, onboardingSnap) {
              if (onboardingSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              // If onboarding was seen before, go directly to login
              if (onboardingSnap.data == true) {
                return const SignInScreen();
              }
              // First time - show onboarding
              return const OnboardingFlow();
            },
          );
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
            // Fall back to auth metadata role if users table row has no role set
            final role = (userSnap.data?['role']?.toString().isNotEmpty == true)
                ? userSnap.data!['role'].toString()
                : client.auth.currentUser?.userMetadata?['role']?.toString();

            if (role != 'sitter') {
              // Check if this is a fresh OAuth sign-in (non-email provider, account
              // created within the last 60 seconds) — if so, auto-claim sitter role.
              final user = client.auth.currentUser;
              final provider = user?.appMetadata['provider']?.toString() ?? 'email';
              final isRecentOAuth = user != null &&
                  provider != 'email' &&
                  DateTime.now()
                      .difference(DateTime.parse(user.createdAt))
                      .inSeconds < 300;

              if (isRecentOAuth) {
                return FutureBuilder<bool>(
                  future: _claimSitterRole(),
                  builder: (ctx, claimSnap) {
                    if (claimSnap.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (claimSnap.data == true) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _refreshUserRow();
                      });
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _wrongRoleScreen();
                  },
                );
              }
              return _wrongRoleScreen();
            }

            return StreamBuilder<Map<String, dynamic>?>(
              stream: ProfileRepository(client).watchSitterProfileRow(),
              builder: (context, spSnap) {
                if (spSnap.connectionState == ConnectionState.waiting && !spSnap.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final row = spSnap.data;
                final active = row != null && row['is_active'] == true;
                if (!active) {
                  return const ProfileUnderReviewScreen();
                }
                return const HomeScreen();
              },
            );
          },
        );
      },
    ),
    );
  }
}
