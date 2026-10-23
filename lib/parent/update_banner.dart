import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/update/app_update.dart';
import 'parent_gate.dart';

/// "A new version is ready" on the start screens, for the parent (ADR-0020).
/// Update asks the parent gate first, then opens the download page in the
/// browser; Later hides it until the next version.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider.select((s) => s.available));
    if (update == null) return const SizedBox.shrink();
    final controller = ref.read(updateProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        key: const ValueKey('update-banner'),
        color: const Color(0xFFE3F0FB),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF2170B5),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'A new version is ready (${update.name}) • '
                      'نسخة جديدة من البرنامج جاهزة',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    key: const ValueKey('update-later'),
                    onPressed: controller.dismiss,
                    child: const Text('Later • بعدين'),
                  ),
                  FilledButton(
                    key: const ValueKey('update-now'),
                    onPressed: () async {
                      await ref.read(narrationProvider).stop();
                      if (!context.mounted ||
                          !await parentGate(
                            context,
                            gender: ref.read(appProvider).profile?.gender,
                          )) {
                        return;
                      }
                      await controller.openDownload();
                    },
                    child: const Text('Update • حدّث'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
