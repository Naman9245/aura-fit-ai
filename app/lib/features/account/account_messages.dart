import 'package:aurafit/data/account.dart';

/// What the screens say when an account step fails. A wrong password and an
/// email with no account read the same.
String messageFor(AccountFailure failure) => switch (failure) {
  AccountFailure.offline =>
    'You\'re offline. Check your connection and try again.',
  AccountFailure.wrongDetails => 'That email and password don\'t match.',
  AccountFailure.notConfirmed =>
    'Confirm your email first: we\'ve sent you a new code.',
  AccountFailure.badCode =>
    'That code is wrong or has run out. Check it, or send a new one.',
  AccountFailure.weakPassword =>
    'Use a password of at least 8 characters that\'s hard to guess.',
  AccountFailure.tooManyTries =>
    'Too many tries for now. Wait a few minutes, then try again.',
  AccountFailure.failed => 'Something went wrong. Please try again.',
};

/// The shortest password the server takes.
const minPasswordLength = 8;

/// Whether [email] looks like an address. The server has the last word.
bool looksLikeEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

/// An email as the account keeps it: no spaces around, lower case.
String tidyEmail(String email) => email.trim().toLowerCase();
