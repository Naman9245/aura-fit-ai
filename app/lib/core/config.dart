/// Where AURA's server lives, set when the app is built:
///
///     flutter run --dart-define-from-file=env/supabase.json
///
/// The publishable key and Google's client ID are public by design: row-level
/// security guards everything behind them. A build without them can't sign
/// in, and says so rather than quietly keeping everything on the phone.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Google's ID for the server side of sign-in, which Supabase checks
  /// Google sign-ins against. Without it there's no Google button.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static bool get isSet => url.isNotEmpty && publishableKey.isNotEmpty;
}
