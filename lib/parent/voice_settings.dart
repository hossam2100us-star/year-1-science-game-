import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/providers.dart';
import '../core/widgets.dart';
import '../core/narration.dart';
import 'parent_gate.dart';

class VoiceSettings extends ConsumerWidget {
  const VoiceSettings({super.key, this.arabic = true});
  final bool arabic;

  /// Dropdown value meaning "no saved voice": narration uses the first
  /// offline voice the device reports.
  static const automaticVoice = '';

  static String? chosenVoice(AppData data) =>
      data.profile?.gender == ChildGender.girl
      ? data.settings.girlVoice
      : data.settings.boyVoice;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.read(narrationProvider);
    final data = ref.watch(appProvider);
    String t(String ar, String en) => arabic ? ar : en;
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('الصوت الإنجليزي على الجهاز', 'English voice on this device'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            voice.status == VoiceStatus.ready
                ? t(
                    'متاح ${voice.voices.length} صوت إنجليزي يعمل من غير إنترنت.',
                    '${voice.voices.length} offline English voices available.',
                  )
                : voice.status == VoiceStatus.browserPreview
                ? t(
                    'معاينة المتصفح من غير قراءة صوتية. جرّب الصوت في نسخة APK على التابلت.',
                    'Browser preview has no narration. Test voices in the Android APK.',
                  )
                : t(
                    'مش لاقيين صوت إنجليزي جاهز من غير إنترنت.',
                    'No offline English voice is available.',
                  ),
          ),
          Text(
            t(
              'أندرويد مش بيحدد جنس كل صوت. اسمع الصوت واختار المناسب لزيزو أو زيزي.',
              'Android does not reliably identify voice gender. Listen and choose a suitable voice for Zizo or Zizi.',
            ),
          ),
          if (voice.voices.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('${data.profile?.gender}-${voice.voices.length}'),
              isExpanded: true,
              initialValue: voice.voices.any((v) => v.id == chosenVoice(data))
                  ? chosenVoice(data)
                  : automaticVoice,
              decoration: InputDecoration(
                labelText: t('صوت الشخصية الحالية', 'Voice for this guide'),
              ),
              items: [
                DropdownMenuItem(
                  value: automaticVoice,
                  child: Text(
                    t(
                      'تلقائي (صوت الجهاز الافتراضي)',
                      'Automatic (device default)',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final v in voice.voices)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text(v.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) async {
                if (value == null) return;
                final id = value == automaticVoice ? null : value;
                try {
                  await ref
                      .read(appProvider.notifier)
                      .settings(
                        data.profile?.gender == ChildGender.girl
                            ? data.settings.copyWith(girlVoice: () => id)
                            : data.settings.copyWith(boyVoice: () => id),
                      );
                } catch (_) {
                  if (context.mounted) showSaveError(context);
                }
              },
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => voice.speak(
                  'Hello! I am ${data.profile?.guideName ?? 'Zizo'}. Great thinking, scientist!',
                ),
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(t('جرّب الصوت', 'Try voice')),
              ),
              OutlinedButton(
                onPressed: () => voice.refresh(),
                child: Text(t('افحص الأصوات تاني', 'Check voices again')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t(
              'لو الصوت مش موجود، اعمل الخطوات دي من إعدادات التابلت مرة واحدة:',
              'If no voice is available, use the tablet settings once:',
            ),
          ),
          Text(
            t(
              '١. افتح إعدادات الجهاز.\n٢. ابحث عن «تحويل النص إلى كلام».\n٣. افتح إعدادات محرك الصوت.\n٤. اختار «تثبيت بيانات الصوت».\n٥. نزّل English.\n٦. ارجع للعبة واضغط «افحص الأصوات تاني».',
              '1. Open device Settings.\n2. Search for Text-to-speech.\n3. Open the speech engine settings.\n4. Choose Install voice data.\n5. Download English.\n6. Return and tap Check voices again.',
            ),
          ),
          Text(
            t(
              'أسماء القوايم ممكن تختلف. تنزيل الصوت من إعدادات الجهاز محتاج إنترنت مرة واحدة؛ اللعبة نفسها مفيهاش إذن إنترنت.',
              'Menu names vary. Installing voice data in system settings needs internet once; the game has no internet permission.',
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceHelpButton extends ConsumerWidget {
  const VoiceHelpButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.read(narrationProvider);
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) => Column(
        children: [
          if (voice.status == VoiceStatus.unavailable)
            const Text(
              'Ask a grown-up to set up my voice.\nمحتاجين نجهز الصوت من إعدادات الجهاز.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 22),
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.record_voice_over_rounded),
            label: const Text('Sound help • مساعدة الصوت'),
            onPressed: () async {
              await voice.stop();
              if (!context.mounted ||
                  !await parentGate(context) ||
                  !context.mounted)
                return;
              await showDialog<void>(
                context: context,
                builder: (dialog) => AlertDialog(
                  scrollable: true,
                  content: const SizedBox(
                    width: 650,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: VoiceSettings(),
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(dialog).pop(),
                      child: const Text('رجوع • Back'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
