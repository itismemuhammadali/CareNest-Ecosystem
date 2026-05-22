import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/system_config_service.dart';

/// Global platform config loaded from system_config table after login.
/// Defaults are safe fallbacks used before/if the remote load fails.
late final SystemConfigService systemConfig;

/// Initializes the Supabase singleton using build-time --dart-define values.
///
/// Pass credentials at build time:
///   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
Future<void> initStarSittersSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || anon.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY — pass via --dart-define at build time.',
    );
  }
  await Supabase.initialize(
    url: url,
    anonKey: anon,
    debug: kDebugMode,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  systemConfig = SystemConfigService(Supabase.instance.client);
}
