import 'dart:async';

import 'package:aurafit/data/account.dart';

/// Accounts in memory, with the server's rules for what each step says:
/// a wrong password and an unknown email fail the same way, a new account
/// waits for its code, and so does signing in before confirming.
class FakeAccountService implements AccountService {
  FakeAccountService({
    this.canSignIn = true,
    this.canUseGoogle = true,
    Account? signedIn,
    this.google = const Account(id: 'google-1', email: 'me@gmail.com'),
  }) : _current = signedIn;

  @override
  final bool canSignIn;

  @override
  final bool canUseGoogle;

  /// Who Google's picker signs in as; null backs out of it.
  Account? google;

  /// The code every email gets.
  static const code = '123456';

  /// Email accounts by address: password, and whether it's confirmed.
  final _accounts = <String, ({String id, String password, bool confirmed})>{};

  Account? _current;
  final _changes = StreamController<Account?>.broadcast();

  /// While true, every step fails as if offline.
  bool offline = false;

  /// Codes sent, by email, in order.
  final codesSent = <String>[];

  /// Adds an email account, as if made on another phone.
  void addAccount(
    String email,
    String password, {
    String id = 'email-1',
    bool confirmed = true,
  }) => _accounts[email] = (id: id, password: password, confirmed: confirmed);

  /// Signs in as [account] straight away, as if it signed in before.
  void signInAs(Account account) {
    addAccount(account.email!, 'a-password', id: account.id);
    _current = account;
  }

  /// Ends the session without signing out, as an expired one does.
  void expire() => _set(null);

  @override
  Stream<Account?> watch() async* {
    yield _current;
    yield* _changes.stream;
  }

  @override
  Future<Account?> signInWithGoogle() async {
    _check();
    final picked = google;
    if (picked != null) _set(picked);
    return picked;
  }

  @override
  Future<Account?> createAccount(String email, String password) async {
    _check();
    if (password.length < 8) {
      throw const AccountException(AccountFailure.weakPassword);
    }
    // An email that already has an account gets the same answer, and no
    // code, so nobody can find out it's there.
    if (!_accounts.containsKey(email)) {
      addAccount(
        email,
        password,
        id: 'email-${_accounts.length + 1}',
        confirmed: false,
      );
      codesSent.add(email);
    }
    return null;
  }

  @override
  Future<Account> confirmEmail(String email, String code) async {
    _check();
    final account = _accounts[email];
    if (account == null || code != FakeAccountService.code) {
      throw const AccountException(AccountFailure.badCode);
    }
    _accounts[email] = (
      id: account.id,
      password: account.password,
      confirmed: true,
    );
    return _signInAs(account.id, email);
  }

  @override
  Future<void> sendNewCode(String email) async {
    _check();
    codesSent.add(email);
  }

  @override
  Future<Account> signIn(String email, String password) async {
    _check();
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const AccountException(AccountFailure.wrongDetails);
    }
    if (!account.confirmed) {
      throw const AccountException(AccountFailure.notConfirmed);
    }
    return _signInAs(account.id, email);
  }

  @override
  Future<void> sendResetCode(String email) async {
    _check();
    if (_accounts.containsKey(email)) codesSent.add(email);
  }

  @override
  Future<Account> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _check();
    final account = _accounts[email];
    if (account == null || code != FakeAccountService.code) {
      throw const AccountException(AccountFailure.badCode);
    }
    if (newPassword.length < 8) {
      throw const AccountException(AccountFailure.weakPassword);
    }
    _accounts[email] = (id: account.id, password: newPassword, confirmed: true);
    return _signInAs(account.id, email);
  }

  @override
  Future<void> signOut() async => _set(null);

  /// Accounts deleted, by id, in order.
  final deleted = <String>[];

  @override
  Future<void> deleteAccount() async {
    _check();
    final account = _current;
    if (account == null) throw const AccountException(AccountFailure.failed);
    deleted.add(account.id);
    _accounts.removeWhere((_, a) => a.id == account.id);
  }

  Account _signInAs(String id, String email) {
    final account = Account(id: id, email: email);
    _set(account);
    return account;
  }

  void _check() {
    if (offline) throw const AccountException(AccountFailure.offline);
  }

  void _set(Account? account) {
    _current = account;
    _changes.add(account);
  }
}
