import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design.dart';
import '../core/diagnostics/app_log.dart';
import '../core/diagnostics/failure.dart';
import '../core/storage.dart';
import '../core/widgets.dart';
import '../parent/parent_gate.dart';

/// Why the game could not start, so the screen can say what actually
/// happened instead of always blaming free space (AUD-006, AUD-009).
enum StartupProblem { storageFull, storageUnavailable, contentMissing }

StartupProblem startupProblemFor(Object error) =>
    switch (classifyFailure(error)) {
      FailureKind.storageFull => StartupProblem.storageFull,
      _ => StartupProblem.storageUnavailable,
    };

String _problemText(StartupProblem problem) => switch (problem) {
  StartupProblem.storageFull =>
    'الجهاز مليان ومش قادرين نفتح الحفظ. فضّي مساحة وجرّب تاني. البيانات المحفوظة ما اتمسحتش.\n'
        'This device is full, so the saved progress could not be opened. Free some space and try again. Nothing has been deleted.',
  StartupProblem.storageUnavailable =>
    'مش قادرين نفتح مكان الحفظ دلوقتي. اقفل اللعبة وافتحها تاني. البيانات المحفوظة ما اتمسحتش.\n'
        'The saved progress storage could not be opened right now. Close and reopen the game. Nothing has been deleted.',
  StartupProblem.contentMissing =>
    'ملفات الدروس جوه التطبيق ناقصة أو بايظة. حدّث التطبيق أو نزّله تاني. تقدم الطفل محفوظ.\n'
        'The lesson files inside the app could not be loaded. Update or reinstall the app. Saved progress is safe.',
};

/// Shown when storage cannot be opened or bundled content is missing.
class StartupProblemApp extends StatelessWidget {
  const StartupProblemApp({
    super.key,
    required this.problem,
    required this.onRetry,
  });
  final StartupProblem problem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: adventureTheme(null),
    home: Scaffold(
      body: AdventurePage(
        maxWidth: 650,
        child: Column(
          children: [
            Text(
              _problemText(problem),
              key: const ValueKey('startup-problem'),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 22),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('جرّب تاني • Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shown when the saved data and its last good copy are both unreadable.
/// Nothing is deleted without a parent's explicit confirmation.
class SaveRecoveryApp extends StatelessWidget {
  const SaveRecoveryApp({
    super.key,
    required this.store,
    required this.onRetry,
  });
  final HiveProgressStore store;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: adventureTheme(null),
    home: _SaveRecoveryScreen(store: store, onRetry: onRetry),
  );
}

class _SaveRecoveryScreen extends StatelessWidget {
  const _SaveRecoveryScreen({required this.store, required this.onRetry});
  final HiveProgressStore store;
  final VoidCallback onRetry;

  Future<void> _copy(BuildContext context) async {
    if (!await parentGate(context)) return;
    await Clipboard.setData(ClipboardData(text: store.rescueExport()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اتنسخت البيانات. احفظها في ملف قبل أي خطوة تانية.\n'
            'Data copied. Paste it into a file before doing anything else.',
          ),
        ),
      );
    }
  }

  Future<void> _startAgain(BuildContext context) async {
    if (!await parentGate(context) || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('نبدأ من جديد؟ • Start again?'),
        content: const Text(
          'اللعبة هتبدأ فاضية. نسخة من البيانات البايظة هتفضل محفوظة على الجهاز وتقدر تنسخها بعدين من ركن الأهل.\n'
          'The game will start empty. A copy of the unreadable data stays on this device and can still be copied later from the parent area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('إلغاء • Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('ابدأ من جديد • Start again'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.startAgainKeepingCopy();
      onRetry();
    } catch (error, stack) {
      if (context.mounted) {
        showSaveError(context, error, stack, area: 'recovery');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AdventurePage(
      maxWidth: 700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مش قادرين نقرا التقدم المحفوظ، ولا النسخة الاحتياطية. مفيش حاجة اتمسحت.\n'
            'The saved progress and its last good copy could not be read. Nothing has been deleted.',
            key: ValueKey('save-unreadable'),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 22),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            child: const Text('جرّب تاني • Retry'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('rescue-export'),
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_rounded),
            label: const Text(
              'للأهل: انسخ البيانات • Grown-ups: copy the data',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('start-again'),
            onPressed: () => _startAgain(context),
            child: const Text(
              'للأهل: ابدأ من جديد واحتفظ بنسخة • Grown-ups: start again, keep a copy',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: AppLog.export())),
            child: const Text('انسخ سجل الأعطال • Copy diagnostics'),
          ),
        ],
      ),
    ),
  );
}
