import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/mascot.dart';
import '../../core/widgets.dart';
import '../../parent/parent_gate.dart';
import 'profile_editor.dart';

class ChildChooser extends ConsumerStatefulWidget {
  const ChildChooser({
    super.key,
    required this.onSelected,
    required this.onParentChanged,
  });
  final VoidCallback onSelected;
  final ValueChanged<bool> onParentChanged;
  @override
  ConsumerState<ChildChooser> createState() => _ChildChooserState();
}

class _ChildChooserState extends ConsumerState<ChildChooser> {
  bool busy = false;
  Future<void> remove(String id, String name) async {
    if (busy) return;
    setState(() => busy = true);
    widget.onParentChanged(true);
    try {
      await ref.read(narrationProvider).stop();
      if (!mounted || !await parentGate(context) || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text('حذف ملف $name؟'),
          content: const Text(
            'سيتم حذف اسم الطفل وصورته وتقدمه وإعداداته من هذا الجهاز. لا يمكن التراجع عن الحذف. ملفات الأطفال الآخرين ستبقى محفوظة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-child'),
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('حذف الملف'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await ref.read(appProvider.notifier).removeChild(id);
      }
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack);
    } finally {
      widget.onParentChanged(false);
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> choose(String id) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref.read(narrationProvider).stop();
      await ref.read(appProvider.notifier).selectChild(id);
      if (mounted) widget.onSelected();
    } catch (error, stack) {
      if (mounted) showSaveError(context, error, stack);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> add() async {
    if (busy) return;
    await ref.read(narrationProvider).stop();
    if (!mounted || !await parentGate(context) || !mounted) return;
    widget.onParentChanged(true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileEditor(newChild: true),
        ),
      );
    } finally {
      widget.onParentChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref
        .watch(appProvider)
        .childRecords
        .entries
        .where((e) => e.value['profile'] != null);
    return Scaffold(
      body: AdventurePage(
        maxWidth: 950,
        child: Column(
          children: [
            if (Navigator.of(context).canPop())
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            Text(
              'Who is playing?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Text('Choose your profile and start exploring'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                for (final child in children)
                  _card(
                    child.key,
                    ChildProfile.fromJson(
                      Map<String, dynamic>.from(child.value['profile']),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              key: const ValueKey('add-child'),
              onPressed: busy ? null : add,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add a child'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String id, ChildProfile profile) => Material(
    color: const Color(0xFFE2F0EA),
    borderRadius: BorderRadius.circular(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          key: ValueKey('child-$id'),
          onTap: busy ? null : () => choose(id),
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  ChildAvatar(profile: profile, size: 100),
                  const SizedBox(height: 16),
                  Text(
                    profile.name.isEmpty ? 'Scientist' : profile.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton.icon(
          key: ValueKey('delete-child-$id'),
          onPressed: busy ? null : () => remove(id, profile.name),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete profile • Grown-ups'),
        ),
      ],
    ),
  );
}
