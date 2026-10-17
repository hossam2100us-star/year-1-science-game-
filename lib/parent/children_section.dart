import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/mascot.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/widgets.dart';
import '../data/sync/sync_controller.dart';
import '../l10n/parent_strings.dart';
import 'parent_section.dart';

/// The children saved on this device, each with "Delete profile". Deleting
/// lives here, behind the parent gate of the parent area, rather than on the
/// child's card in "Who is playing?" (teacher review 6).
class ChildrenOnDevice extends ConsumerStatefulWidget {
  const ChildrenOnDevice({super.key, required this.arabic});
  final bool arabic;

  @override
  ConsumerState<ChildrenOnDevice> createState() => _ChildrenOnDeviceState();
}

class _ChildrenOnDeviceState extends ConsumerState<ChildrenOnDevice> {
  bool _busy = false;

  AppLocalizations get l => parentStrings(widget.arabic);

  Future<void> _delete(String id, String name) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => Directionality(
          textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(l.childChooserDeleteTitle(name)),
            content: Text(
              ref.read(syncProvider).linked.contains(id)
                  ? '${l.childChooserDeleteBody}\n\n${l.childChooserDeleteLinked}'
                  : l.childChooserDeleteBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: Text(l.childChooserCancel),
              ),
              FilledButton(
                key: const ValueKey('confirm-delete-child'),
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(l.childChooserDeleteConfirm),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final active = ref.read(appProvider).activeChildId == id;
      await ref.read(appProvider.notifier).removeChild(id);
      // The parent area belongs to the child who was playing; with that
      // child gone, go back to "Who is playing?" (or the first-run screen).
      if (active && mounted) await Navigator.of(context).maybePop();
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref
        .watch(appProvider)
        .childRecords
        .entries
        .where((e) => e.value['profile'] != null);
    return ParentSection(
      title: l.parentAreaChildrenOnDevice,
      children: [
        for (final child in children)
          Builder(
            builder: (context) {
              final profile = ChildProfile.fromJson(
                Map<String, dynamic>.from(child.value['profile']),
              );
              final name = profile.name.isEmpty
                  ? l.parentAreaNameNotEntered
                  : profile.name;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ChildAvatar(profile: profile, size: 44),
                title: Text(name),
                trailing: TextButton.icon(
                  key: ValueKey('delete-child-${child.key}'),
                  onPressed: _busy ? null : () => _delete(child.key, name),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.childChooserDeleteConfirm),
                ),
              );
            },
          ),
      ],
    );
  }
}
