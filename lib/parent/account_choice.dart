import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/providers.dart';
import '../core/widgets.dart';
import '../data/account/account_controller.dart';
import '../l10n/parent_strings.dart';
import 'account_panel.dart';
import 'parent_gate.dart';
import 'parent_section.dart';

/// The first-run question on builds with parent accounts (ADR-0002), asked
/// once: "this device only" (the default: no Internet, so no gate is
/// needed) or a parent account (behind the parent gate and the consent).
/// Either choice can be changed later in the parent area.
class AccountChoice extends ConsumerWidget {
  const AccountChoice({super.key});

  Future<void> _account(BuildContext context, WidgetRef ref, bool ar) async {
    final navigator = Navigator.of(context);
    if (!await parentGate(context) || !context.mounted) return;
    if (!await askAccountConsent(context, arabic: ar)) return;
    await ref.read(accountProvider.notifier).useAccount();
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const AccountSetupPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appProvider.select((d) => d.settings.arabic));
    final l = parentStrings(ar);
    return _ParentPage(
      arabic: ar,
      children: [
        Text(l.choiceTitle, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(l.choiceBody),
        const SizedBox(height: 22),
        ParentSection(
          title: l.accountDeviceOnlyTitle,
          children: [
            Text(l.accountDeviceOnlyBody),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('choice-device'),
              onPressed: () =>
                  ref.read(accountProvider.notifier).chooseDeviceOnly(),
              icon: const Icon(Icons.phone_android_rounded),
              label: Text(l.choiceDeviceButton),
            ),
          ],
        ),
        ParentSection(
          title: l.accountWhyTitle,
          children: [
            Text(l.accountWhyBody),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('choice-account'),
              onPressed: () => _account(context, ref, ar),
              icon: const Icon(Icons.family_restroom_rounded),
              label: Text(l.accountUseAccount),
            ),
          ],
        ),
      ],
    );
  }
}

/// Signing in (or creating the account) right after the first-run choice;
/// the account's children arrive on this device once signed in.
class AccountSetupPage extends ConsumerWidget {
  const AccountSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = ref.watch(appProvider.select((d) => d.settings.arabic));
    final l = parentStrings(ar);
    return _ParentPage(
      arabic: ar,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            key: const ValueKey('choice-continue'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l.choiceContinue),
          ),
        ),
        const SizedBox(height: 22),
        AccountPanel(arabic: ar),
      ],
    );
  }
}

/// The parent area's look: its font, the parent's language and a language
/// switch.
class _ParentPage extends ConsumerWidget {
  const _ParentPage({required this.arabic, required this.children});
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

/// After a child is created while a parent is signed in: offer to save it
/// in the account (the parent confirms behind the gate). Returns whether
/// the parent agreed.
Future<bool> offerToSaveChild(
  BuildContext context, {
  required bool arabic,
  required String name,
  ChildGender? gender,
}) async {
  final l = parentStrings(arabic);
  final save = await showDialog<bool>(
    context: context,
    builder: (dialog) => Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        scrollable: true,
        title: Text(l.accountLinkConfirmTitle(name)),
        content: Text(l.accountLinkConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('offer-not-now'),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.accountNotNow),
          ),
          FilledButton(
            key: const ValueKey('offer-save'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.accountLink),
          ),
        ],
      ),
    ),
  );
  if (save != true || !context.mounted) return false;
  return parentGate(context, gender: gender);
}
