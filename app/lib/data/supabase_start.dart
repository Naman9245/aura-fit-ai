import 'package:aurafit/core/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<SupabaseClient>? _started;

/// AURA's server, started once, the first time anything needs it. It brings
/// back a saved sign-in from the phone, without the network. A start that
/// fails is tried again next time.
Future<SupabaseClient> startSupabase() => _started ??= _start();

Future<SupabaseClient> _start() async {
  try {
    final supabase = await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return supabase.client;
  } catch (_) {
    _started = null;
    rethrow;
  }
}
