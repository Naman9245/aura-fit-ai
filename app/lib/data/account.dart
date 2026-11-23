import 'dart:async';

import 'package:aurafit/core/config.dart';
import 'package:aurafit/data/supabase_start.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The account this phone's data belongs to on AURA's server.
@immutable
class Account {
  const Account({required this.id, this.email});

  /// Its id on the server: whose rows they are.
  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is Account && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Why an account step didn't work. The screens give each one message.
enum AccountFailure {
  /// No internet, or the server didn't answer.
  offline,

  /// The email and password don't match an account. An email with no
  /// account gets this too, so nobody can find out which emails have one.
  wrongDetails,

  /// The account exists, but its email isn't confirmed yet.
  notConfirmed,

  /// The code is wrong, or has run out.
  badCode,

  /// The password is too short or too easy to guess.
  weakPassword,

  /// Too many tries or emails for now.
  tooManyTries,

  /// Anything else.
  failed,
}

class AccountException implements Exception {
  const AccountException(this.failure, [this.detail]);

  final AccountFailure failure;

  /// The server's error code, for logs; never shown.
  final String? detail;

  @override
  String toString() => 'AccountException(${failure.name}, $detail)';
}

/// Signing in, with Google or an email and password, and out again.
abstract interface class AccountService {
  /// Whether this build knows AURA's server at all.
  bool get canSignIn;

  /// Whether this build can sign in with Google.
  bool get canUseGoogle;

  /// The signed-in account, as it changes; null when there isn't one.
  Stream<Account?> watch();

  /// Signs in through Google's account picker. Null when the person backs
  /// out of it.
  Future<Account?> signInWithGoogle();

  /// Creates an account. Null when the server sent a 6-digit code to
  /// [email] to confirm it first, which it does whether or not the email
  /// already has an account.
  Future<Account?> createAccount(String email, String password);

  /// Confirms a new account's email with the [code] sent to it.
  Future<Account> confirmEmail(String email, String code);

  /// Sends a new code to confirm [email].
  Future<void> sendNewCode(String email);

  Future<Account> signIn(String email, String password);

  /// Sends a code to reset [email]'s password. It says nothing about
  /// whether the email has an account.
  Future<void> sendResetCode(String email);

  /// Signs in with the reset [code] and sets [newPassword].
  Future<Account> resetPassword(String email, String code, String newPassword);

  Future<void> signOut();
}

/// [AccountService] over Supabase Auth. Google's own sign-in on the phone
/// gives an ID token, which signs in to Supabase; email accounts confirm
/// with a code, so no link has to find its way back into the app.
class SupabaseAccountService implements AccountService {
  SupabaseAccountService({this.webClientId = SupabaseConfig.googleWebClientId});

  /// Google's id for Supabase's side of sign-in.
  final String webClientId;

  /// Google's sign-in, set up once, the first time it's needed.
  Future<void>? _google;

  @override
  bool get canSignIn => SupabaseConfig.isSet;

  @override
  bool get canUseGoogle => canSignIn && webClientId.isNotEmpty;

  @override
  Stream<Account?> watch() async* {
    if (!canSignIn) {
      yield null;
      return;
    }
    final client = await startSupabase();
    yield _accountOf(client.auth.currentUser);
    yield* client.auth.onAuthStateChange.map(
      (change) => _accountOf(change.session?.user),
    );
  }

  static Account? _accountOf(User? user) => user == null || user.isAnonymous
      ? null
      : Account(id: user.id, email: user.email);

  @override
  Future<Account?> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await (_google ??= google.initialize(serverClientId: webClientId));
    final GoogleSignInAccount picked;
    try {
      picked = await google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw AccountException(AccountFailure.failed, error.code.name);
    }
    final idToken = picked.authentication.idToken;
    if (idToken == null) {
      throw const AccountException(AccountFailure.failed, 'no ID token');
    }
    return _signedIn(
      (auth) => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      ),
    );
  }

  @override
  Future<Account?> createAccount(String email, String password) async {
    final client = await startSupabase();
    final AuthResponse response;
    try {
      response = await client.auth.signUp(email: email, password: password);
    } on AuthException catch (error) {
      throw _failureOf(error);
    }
    // With "Confirm email" on, there's no session until the code is in.
    return response.session == null ? null : _accountOf(response.user);
  }

  @override
  Future<Account> confirmEmail(String email, String code) => _signedIn(
    (auth) => auth.verifyOTP(type: OtpType.signup, email: email, token: code),
  );

  @override
  Future<void> sendNewCode(String email) =>
      _call((auth) => auth.resend(type: OtpType.signup, email: email));

  @override
  Future<Account> signIn(String email, String password) => _signedIn(
    (auth) => auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<void> sendResetCode(String email) =>
      _call((auth) => auth.resetPasswordForEmail(email));

  @override
  Future<Account> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final account = await _signedIn(
      (auth) =>
          auth.verifyOTP(type: OtpType.recovery, email: email, token: code),
    );
    await _call(
      (auth) => auth.updateUser(UserAttributes(password: newPassword)),
    );
    return account;
  }

  @override
  Future<void> signOut() async {
    if (!canSignIn) return;
    final client = await startSupabase();
    try {
      await client.auth.signOut();
    } on AuthException {
      // Offline: the phone is signed out already, and the server lets the
      // session lapse on its own.
    }
    if (_google != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // Google's own memory of the choice; nothing here depends on it.
      }
    }
  }

  /// Runs an auth call that should end signed in.
  Future<Account> _signedIn(
    Future<AuthResponse> Function(GoTrueClient auth) call,
  ) async {
    final client = await startSupabase();
    final AuthResponse response;
    try {
      response = await call(client.auth);
    } on AuthException catch (error) {
      throw _failureOf(error);
    }
    final account = _accountOf(response.user ?? response.session?.user);
    if (account == null) {
      throw const AccountException(AccountFailure.failed, 'no user');
    }
    return account;
  }

  Future<void> _call(Future<Object?> Function(GoTrueClient auth) call) async {
    final client = await startSupabase();
    try {
      await call(client.auth);
    } on AuthException catch (error) {
      throw _failureOf(error);
    }
  }

  static AccountException _failureOf(AuthException error) {
    final detail = error.code ?? error.statusCode;
    if (error is AuthRetryableFetchException) {
      return AccountException(AccountFailure.offline, detail);
    }
    if (error is AuthWeakPasswordException) {
      return AccountException(AccountFailure.weakPassword, detail);
    }
    final failure = switch (error.code) {
      'invalid_credentials' || 'user_not_found' => AccountFailure.wrongDetails,
      'email_not_confirmed' => AccountFailure.notConfirmed,
      'otp_expired' => AccountFailure.badCode,
      'weak_password' => AccountFailure.weakPassword,
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' => AccountFailure.tooManyTries,
      // Older servers say only this.
      _ when error.message == 'Invalid login credentials' =>
        AccountFailure.wrongDetails,
      _ when error.statusCode == '429' => AccountFailure.tooManyTries,
      _ => AccountFailure.failed,
    };
    return AccountException(failure, detail);
  }
}

final accountServiceProvider = Provider<AccountService>(
  (ref) => SupabaseAccountService(),
);

/// The signed-in account, if any.
final accountProvider = StreamProvider<Account?>(
  (ref) => ref.watch(accountServiceProvider).watch().distinct(),
);
