import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/widgets.dart';
import '../data/account/account_controller.dart';
import '../l10n/parent_strings.dart';
import 'account_panel.dart';
import 'parent_section.dart';
import 'update_banner.dart';

/// The first page each time the app opens until a parent signs in (owner's
/// decision, 16 October 2026): sign in to the parent account, or continue
/// without the Internet with what is saved on this device. Continuing
/// offline needs nothing and never touches the network; the page comes
/// back the next time the app opens. Signed in, the app goes straight in.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.onOffline});

  /// The parent (or child) chose to continue without signing in.
  final VoidCallback onOffline;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// The account was turned on here, for a sign-in that has not happened.
  bool _turnedOn = false;
  bool _leaving = false;

  bool get _arabic => ref.read(appProvider).settings.arabic;

  /// Before the first request: the parent agrees to what an account stores
  /// (as before), and the account is turned on. Nothing is sent until then.
  Future<bool> _prepare() async {
    if (ref.read(accountProvider).mode == AccountMode.account) return true;
    if (!await askAccountConsent(context, arabic: _arabic)) return false;
    await ref.read(accountProvider.notifier).useAccount();
    _turnedOn = true;
    return true;
  }

  Future<void> _offline() async {
    if (_leaving) return;
    _leaving = true;
    final account = ref.read(accountProvider);
    final notifier = ref.read(accountProvider.notifier);
    try {
      if (_turnedOn && !account.signedIn) {
        // Back to this device only: no account client, no network at all.
        await notifier.useDeviceOnly();
      } else if (account.mode == AccountMode.deviceOnly) {
        await notifier.chooseDeviceOnly();
      }
    } finally {
      _leaving = false;
    }
    widget.onOffline();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = ref.watch(appProvider.select((d) => d.settings.arabic));
    final l = parentStrings(arabic);
    final signIn = Localizations.override(
      context: context,
      locale: Locale(arabic ? 'ar' : 'en'),
      child: AccountSignInForm(arabic: arabic, prepare: _prepare),
    );
    final offlineButton = FilledButton.icon(
      key: const ValueKey('login-offline'),
      onPressed: _offline,
      icon: const Icon(Icons.wifi_off_rounded),
      label: Text(l.loginOffline),
    );
    final title = Text(
      l.choiceTitle,
      style: Theme.of(context).textTheme.headlineLarge,
    );
    // A phone on its side is short: continuing offline goes next to the
    // title, so a child never has to scroll to start playing.
    if (MediaQuery.sizeOf(context).height < 560) {
      return ParentPage(
        arabic: arabic,
        children: [
          const UpdateBanner(),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [title, offlineButton],
          ),
          const SizedBox(height: 12),
          Text(l.loginBody),
          const SizedBox(height: 12),
          signIn,
        ],
      );
    }
    final offline = ParentSection(
      title: l.accountDeviceOnlyTitle,
      children: [
        Text(l.loginOfflineBody),
        const SizedBox(height: 12),
        offlineButton,
      ],
    );
    return ParentPage(
      arabic: arabic,
      children: [
        const UpdateBanner(),
        title,
        const SizedBox(height: 12),
        Text(l.loginBody),
        const SizedBox(height: 22),
        // Side by side on a tablet, so continuing offline is on the first
        // screen; one above the other on a narrow screen.
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: signIn),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: offline),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [signIn, offline],
                ),
        ),
      ],
    );
  }
}

/// The parent pages' look: their font, the parent's language and a
/// language switch.
class ParentPage extends ConsumerWidget {
  const ParentPage({super.key, required this.arabic, required this.children});
  final bool arabic;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: arabic ? 'Cairo' : 'Nunito'),
    );
    return Theme(
      data: theme,
      child: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: AdventurePage(
            maxWidth: 950,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    key: const ValueKey('parent-page-language'),
                    onPressed: () {
                      final app = ref.read(appProvider);
                      ref
                          .read(appProvider.notifier)
                          .settings(app.settings.copyWith(arabic: !arabic));
                    },
                    child: Text(arabic ? 'English' : 'العربية'),
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
