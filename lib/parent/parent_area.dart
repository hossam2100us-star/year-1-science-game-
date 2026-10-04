import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/diagnostics/app_log.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/storage.dart';
import '../core/widgets.dart';
import 'voice_settings.dart';
import '../features/onboarding/profile_editor.dart';
import 'parent_gate.dart';
import 'unit_report.dart';

class ParentArea extends ConsumerStatefulWidget {
  const ParentArea({super.key});
  @override
  ConsumerState<ParentArea> createState() => _ParentAreaState();
}

class _ParentAreaState extends ConsumerState<ParentArea> {
  int _tab = 0;

  bool _needsRecovery(AppData data) {
    final store = ref.read(storeProvider);
    return data.quarantinedChildren.isNotEmpty ||
        store.recovery == StorageRecovery.restoredFromBackup ||
        store.hasUnreadableCopies;
  }

  Future<void> _discardDamaged(
    BuildContext context,
    String Function(String, String) t,
  ) async {
    if (!await parentGate(
          context,
          gender: ref.read(appProvider).profile?.gender,
        ) ||
        !context.mounted)
      return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(t('تمسح النسخ البايظة؟', 'Delete the damaged copies?')),
        content: Text(
          t(
            'اتأكد إنك نسخت البيانات وحفظتها الأول. المسح نهائي.',
            'Make sure you copied and kept the data first. This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(t('إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(t('امسح', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(appProvider.notifier).discardQuarantine();
      await ref.read(storeProvider).discardUnreadableCopies();
      if (mounted) setState(() {});
    } catch (error, stack) {
      if (context.mounted) {
        showSaveError(context, error, stack, area: 'recovery');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final settings = data.settings;
    final ar = settings.arabic;
    String t(String arabic, String english) => ar ? arabic : english;
    Future<void> save(AppSettings value) async {
      try {
        await ref.read(appProvider.notifier).settings(value);
      } catch (error, stack) {
        if (context.mounted) showSaveError(context, error, stack);
      }
    }

    final parentTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: ar ? 'Cairo' : 'Nunito'),
    );
    return Theme(
      data: parentTheme,
      child: Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: AdventurePage(
            maxWidth: 950,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(t('ارجع للطفل', 'Back to child')),
                    ),
                    OutlinedButton(
                      onPressed: () => save(settings.copyWith(arabic: !ar)),
                      child: Text(ar ? 'English' : 'العربية'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t('ركن الأهل', 'Grown-ups'),
                  style: parentTheme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    'تابع تقدم الطفل من قراراته أثناء اللعب. التوقعات واللعب الحر مش درجات.',
                    'Follow learning through play decisions. Predictions and free play are not graded.',
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < 3; i++)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _tab = i),
                        icon: Icon(
                          _tab == i
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                        ),
                        label: Text(
                          [
                            t('النتائج', 'Results'),
                            t('الإعدادات', 'Settings'),
                            t('دليل الاستخدام', 'Guide'),
                          ][i],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                if (_tab == 1)
                  _Section(
                    title: t(
                      'بيانات الطفل وشكل اللعبة',
                      'Child and appearance',
                    ),
                    children: [
                      Text(
                        t(
                          'الاسم: ${data.profile!.name.isEmpty ? 'مش مكتوب' : data.profile!.name}',
                          'Name: ${data.profile!.name.isEmpty ? 'Not entered' : data.profile!.name}',
                        ),
                      ),
                      Text(
                        t(
                          'الشخصية المرافقة: ${data.profile!.guideName}',
                          'Scientist guide: ${data.profile!.guideName}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileEditor(editing: true),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(
                          t(
                            'غيّر الاسم أو الجنس أو الصورة',
                            'Edit name, gender or picture',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(t('ألوان اللعبة', 'Adventure colours')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final palette in PaletteChoice.values)
                            OutlinedButton.icon(
                              onPressed: () async {
                                final p = data.profile!;
                                try {
                                  await ref
                                      .read(appProvider.notifier)
                                      .saveProfile(
                                        ChildProfile(
                                          name: p.name,
                                          gender: p.gender,
                                          avatar: p.avatar,
                                          photo: p.photo,
                                          palette: palette,
                                        ),
                                      );
                                } catch (error, stack) {
                                  if (context.mounted)
                                    showSaveError(context, error, stack);
                                }
                              },
                              icon: Icon(
                                data.profile!.palette == palette
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                              ),
                              label: Text(switch (palette) {
                                PaletteChoice.automatic => t(
                                  'حسب اختيار الطفل',
                                  'Automatic',
                                ),
                                PaletteChoice.ocean => t('أزرق', 'Ocean'),
                                PaletteChoice.berry => t('بنفسجي', 'Berry'),
                                PaletteChoice.forest => t('أخضر', 'Forest'),
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t(
                          'تغيير البيانات مش بيمسح التقدم. الاسم الأول والصورة والاختيارات بتفضل على الجهاز بس.',
                          'Editing this profile keeps progress. The first name, photo and preferences stay on this device.',
                        ),
                      ),
                    ],
                  ),
                if (_tab == 0)
                  _Section(
                    title: t('تقييم كل وحدة', 'Unit assessment'),
                    children: [
                      Text(
                        t(
                          'النجوم للمجهود والإكمال. تقييم الفهم بيتحسب من أول قرار قبل التلميح؛ التوقع واللعب الحر مش درجات.',
                          'Stars reward effort and completion. Understanding uses first decisions before hints. Predictions and free play are not graded.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final level in ref.read(catalogProvider).levels)
                        UnitReport(level: level, arabic: ar),
                    ],
                  ),
                if (_tab == 0)
                  _Section(
                    title: t('وقت الاستخدام', 'Time on the child screens'),
                    children: [
                      if (data.dailySeconds.isEmpty)
                        Text(t('لسه مفيش وقت مسجل', 'No time recorded yet')),
                      for (final entry
                          in data.dailySeconds.entries.toList().reversed.take(
                            7,
                          ))
                        Text(
                          '${entry.key} • ${(entry.value / 60).floor()} ${t('دقيقة', 'min')}',
                        ),
                      Text(
                        t(
                          'الوقت ده وقت فتح شاشات الطفل، مش دليل على التعلم. وقت ركن الأهل والخلفية مش بيتحسب.',
                          'Time on child screens is not a learning score. Parent-area and background time are excluded.',
                        ),
                      ),
                    ],
                  ),
                if (_tab == 1)
                  _Section(
                    title: t('الراحة والصوت', 'Breaks and audio'),
                    children: [
                      Text(
                        t(
                          'تذكير راحة كل ${settings.breakMinutes} دقيقة',
                          'A gentle break every ${settings.breakMinutes} minutes',
                        ),
                      ),
                      Slider(
                        value: settings.breakMinutes.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 25,
                        label: '${settings.breakMinutes}',
                        onChanged: (v) =>
                            save(settings.copyWith(breakMinutes: v.round())),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t('قراءة الكلام', 'Narration')),
                        value: settings.narration,
                        onChanged: (v) => save(settings.copyWith(narration: v)),
                      ),
                      Text(t('مستوى صوت القراءة', 'Narration volume')),
                      Slider(
                        value: settings.volume,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        onChanged: (v) => save(settings.copyWith(volume: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t(
                            'المؤثرات — هتتوفر مع الألعاب',
                            'Sound effects — with the games',
                          ),
                        ),
                        value: settings.sound,
                        onChanged: (v) => save(settings.copyWith(sound: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          t('الموسيقى — هتتوفر لاحقًا', 'Music — coming later'),
                        ),
                        value: settings.music,
                        onChanged: (v) => save(settings.copyWith(music: v)),
                      ),
                      VoiceSettings(arabic: ar),
                    ],
                  ),
                if (_tab == 2)
                  _Section(
                    title: t('نستخدم اللعبة إزاي؟', 'How to use the adventure'),
                    children: [
                      for (final rule in ref.read(catalogProvider).parentRules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(rule[ar ? 'ar' : 'en'] as String),
                        ),
                      Text(
                        t(
                          'مبني على قواعد الكتاب، صفحة ٢.',
                          'Based on the book, page 2.',
                        ),
                      ),
                    ],
                  ),
                if (_tab == 1)
                  _Section(
                    title: t('مسح التقدم', 'Reset progress'),
                    children: [
                      Text(
                        t(
                          'ده بيمسح النتائج والوقت والنجوم بس، وبيسيب اسم الطفل وصورته والإعدادات.',
                          'This clears results, time and stars, keeping the profile, photo and settings.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          if (!await parentGate(
                                context,
                                gender: ref.read(appProvider).profile?.gender,
                              ) ||
                              !context.mounted)
                            return;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialog) => AlertDialog(
                              title: Text(
                                t(
                                  'متأكد من مسح التقدم؟',
                                  'Clear all progress?',
                                ),
                              ),
                              content: Text(
                                t(
                                  'المسح نهائي ومفيش رجوع.',
                                  'This cannot be undone.',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialog).pop(false),
                                  child: Text(t('إلغاء', 'Cancel')),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialog).pop(true),
                                  child: Text(
                                    t('امسح التقدم', 'Clear progress'),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await ref
                                  .read(appProvider.notifier)
                                  .resetProgress();
                            } catch (error, stack) {
                              if (context.mounted)
                                showSaveError(context, error, stack);
                            }
                          }
                        },
                        child: Text(
                          t(
                            'مسح التقدم بعد التأكيد',
                            'Reset with confirmation',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_tab == 1 && _needsRecovery(data))
                  _Section(
                    title: t('بيانات محتاجة مراجعة', 'Data needing attention'),
                    children: [
                      Text(
                        key: const ValueKey('recovery-summary'),
                        t(
                          'في بيانات محفوظة ما قدرناش نقراها، وما اتمسحتش. عدد سجلات الأطفال المتأثرة: ${data.quarantinedChildren.length}.${ref.read(storeProvider).recovery == StorageRecovery.restoredFromBackup ? ' اللعبة رجعت لآخر نسخة سليمة.' : ''} انسخ البيانات واحفظها في ملف، وبعدين تقدر تمسح النسخ البايظة.',
                          'Some saved data could not be read and has not been deleted. Affected child records: ${data.quarantinedChildren.length}.${ref.read(storeProvider).recovery == StorageRecovery.restoredFromBackup ? ' The game restored the last good copy.' : ''} Copy the data and keep it in a file; afterwards you can delete the damaged copies.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('copy-rescue'),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: ref.read(storeProvider).rescueExport(),
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      t('اتنسخت البيانات', 'Data copied'),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(t('انسخ البيانات', 'Copy the data')),
                          ),
                          OutlinedButton(
                            key: const ValueKey('discard-damaged'),
                            onPressed: () => _discardDamaged(context, t),
                            child: Text(
                              t('امسح النسخ البايظة', 'Delete damaged copies'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_tab == 1)
                  _Section(
                    title: t('سجل الأعطال', 'Diagnostics'),
                    children: [
                      Text(
                        t(
                          'لو حصلت مشكلة في الحفظ أو الصوت، انسخ السجل وابعته للدعم بنفسك. السجل فيه نوع العطل ومكانه في الكود بس؛ مفيهوش اسم الطفل أو صورته، ومش بيتبعت لأي حد تلقائيًا.',
                          'If saving or sound goes wrong, copy this log and send it to support yourself. It holds only error types and code locations — never the child\'s name or photo — and is never sent automatically.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('copy-diagnostics'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: AppLog.export()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t('اتنسخ السجل', 'Log copied')),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(t('انسخ السجل', 'Copy log')),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}
