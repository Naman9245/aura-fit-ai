import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// The pages on AURA's website that the app links to. Google Play asks for
/// the privacy policy inside the app as well as on the store listing.
///
/// The site lives on GitHub Pages until AURA has its own domain; change
/// [website] then, and nothing else.
abstract final class AuraLinks {
  static final Uri website = Uri.parse(
    'https://naman9245.github.io/aura-fit-ai/',
  );
  static final Uri privacy = website.resolve('privacy/');
  static final Uri terms = website.resolve('terms/');
}

/// Opens a web page in the phone's browser. Tests override it to record the
/// address instead.
final openLinkProvider = Provider<Future<void> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// "Privacy policy · Terms", as two small links.
class LegalLinks extends ConsumerWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(openLinkProvider);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => open(AuraLinks.privacy),
          child: const Text('Privacy policy'),
        ),
        const Text('·'),
        TextButton(
          onPressed: () => open(AuraLinks.terms),
          child: const Text('Terms'),
        ),
      ],
    );
  }
}
