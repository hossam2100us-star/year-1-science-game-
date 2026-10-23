import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account/account_controller.dart';
import '../data/update/app_update.dart';
import '../l10n/parent_strings.dart';
import 'parent_section.dart';

/// The parent's switch for the update check, and this app's version
/// (ADR-0020). Shown only on Android builds that know the family server.
class UpdateSettings extends ConsumerWidget {
  const UpdateSettings({super.key, required this.arabic});
  final bool arabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(appPlatformProvider) == null ||
        ref.watch(accountSetupProvider).server == null) {
      return const SizedBox.shrink();
    }
    final l = parentStrings(arabic);
    final state = ref.watch(updateProvider);
    return ParentSection(
      title: l.parentAreaUpdatesTitle,
      children: [
        SwitchListTile(
          key: const ValueKey('update-check-switch'),
          contentPadding: EdgeInsets.zero,
          value: state.enabled,
          title: Text(l.parentAreaUpdatesCheck),
          subtitle: Text(l.parentAreaUpdatesNote),
          onChanged: (on) => ref.read(updateProvider.notifier).setEnabled(on),
        ),
        if (state.current case final AppVersion version)
          Text(l.parentAreaVersion(version.name)),
      ],
    );
  }
}
