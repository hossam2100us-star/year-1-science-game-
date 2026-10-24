import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/diagnostics/app_log.dart';
import '../core/models.dart';
import '../core/providers.dart';
import '../core/storage.dart';
import '../core/widgets.dart';
import '../data/account/account_controller.dart';
import '../data/sync/sync_controller.dart';
import 'account_panel.dart';
import 'children_section.dart';
import 'school_years_section.dart';
import 'update_settings.dart';
import 'voice_settings.dart';
import '../features/onboarding/profile_editor.dart';
import 'parent_gate.dart';
import 'parent_section.dart';
import '../l10n/parent_strings.dart';

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

  Future<void> _discardDamaged(BuildContext context, AppLocalizations l) async {
    if (!await parentGate(
          context,
          gender: ref.read(appProvider).profile?.gender,
        ) ||
        !context.mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.parentAreaDeleteTheDamagedCopies),
        content: Text(l.parentAreaMakeSureYouCopiedAnd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.parentAreaCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.parentAreaDelete),
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
    final l = parentStrings(ar);
    Future<void> save(AppSettings value) async {
      try {
        await ref.read(appProvider.notifier).settings(value);
      } catch (error, stack) {
        if (context.mounted) showSaveError(context, error, stack);
      }
    }

    // The account tab exists only in builds that know a server, on installs
    // that can sync (not the web build yet: it has its own parent pages).
    final accounts =
        ref.watch(accountProvider.select((a) => a.available)) &&
        ref.watch(syncProvider.select((s) => s.supported));
    final tabs = [
      l.parentAreaResults,
      l.parentAreaSettings,
      l.parentAreaGuide,
      if (accounts) l.parentAreaAccount,
    ];
    final linked = ref.watch(syncProvider).linked.contains(data.activeChildId);
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
                      label: Text(l.parentAreaBackToChild),
                    ),
                    OutlinedButton(
                      onPressed: () => save(settings.copyWith(arabic: !ar)),
                      child: Text(ar ? 'English' : 'العربية'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l.parentAreaGrownUps,
                  style: parentTheme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(l.parentAreaFollowLearningThroughPlayDecisions),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _tab = i),
                        icon: Icon(
                          _tab == i
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                        ),
                        label: Text(tabs[i]),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                if (_tab == 1)
                  ParentSection(
                    title: l.parentAreaChildAndAppearance,
                    children: [
                      Text(
                        l.parentAreaName(
                          data.profile!.name.isEmpty
                              ? l.parentAreaNameNotEntered
                              : data.profile!.name,
                        ),
                      ),
                      Text(l.parentAreaScientistGuide(data.profile!.guideName)),
                      const SizedBox(height: 12),
                      SchoolYearSetting(arabic: ar),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileEditor(editing: true),
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l.parentAreaEditNameGenderOrPicture),
                      ),
                      const SizedBox(height: 16),
                      Text(l.parentAreaAdventureColours),
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
                                        p.copyWith(palette: palette),
                                      );
                                } catch (error, stack) {
                                  if (context.mounted) {
                                    showSaveError(context, error, stack);
                                  }
                                }
                              },
                              icon: Icon(
                                data.profile!.palette == palette
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                              ),
                              label: Text(switch (palette) {
                                PaletteChoice.automatic =>
                                  l.parentAreaAutomatic,
                                PaletteChoice.ocean => l.parentAreaOcean,
                                PaletteChoice.berry => l.parentAreaBerry,
                                PaletteChoice.forest => l.parentAreaForest,
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        linked
                            ? l.parentAreaEditingLinkedProfile
                            : l.parentAreaEditingThisProfileKeepsProgress,
                      ),
                    ],
                  ),
                if (_tab == 1) ChildrenOnDevice(arabic: ar),
                if (_tab == 1) UpdateSettings(arabic: ar),
                if (_tab == 0) ResultsByYear(arabic: ar),
                if (_tab == 0)
                  ParentSection(
                    title: l.parentAreaTimeOnTheChildScreens,
                    children: [
                      if (data.dailySeconds.isEmpty)
                        Text(l.parentAreaNoTimeRecordedYet),
                      for (final entry
                          in data.dailySeconds.entries.toList().reversed.take(
                            7,
                          ))
                        Text(
                          '${entry.key} • ${(entry.value / 60).floor()} ${l.parentAreaMin}',
                        ),
                      Text(l.parentAreaTimeOnChildScreensIs),
                    ],
                  ),
                if (_tab == 1)
                  ParentSection(
                    title: l.parentAreaBreaksAndAudio,
                    children: [
                      Text(
                        l.parentAreaAGentleBreakEveryMinutes(
                          settings.breakMinutes,
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
                        title: Text(l.parentAreaNarration),
                        value: settings.narration,
                        onChanged: (v) => save(settings.copyWith(narration: v)),
                      ),
                      Text(l.parentAreaNarrationVolume),
                      Slider(
                        value: settings.volume,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        onChanged: (v) => save(settings.copyWith(volume: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.parentAreaSoundEffectsWithTheGames),
                        value: settings.sound,
                        onChanged: (v) => save(settings.copyWith(sound: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.parentAreaMusicComingLater),
                        value: settings.music,
                        onChanged: (v) => save(settings.copyWith(music: v)),
                      ),
                      VoiceSettings(arabic: ar),
                    ],
                  ),
                if (_tab == 3 && accounts) AccountPanel(arabic: ar),
                if (_tab == 2)
                  ParentSection(
                    title: l.parentAreaHowToUseTheAdventure,
                    children: [
                      for (final rule in ref.read(catalogProvider).parentRules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(rule[ar ? 'ar' : 'en'] as String),
                        ),
                      Text(l.parentAreaBasedOnTheBookPage),
                    ],
                  ),
                if (_tab == 2) SubjectGuides(arabic: ar),
                if (_tab == 1)
                  ParentSection(
                    title: l.parentAreaResetProgress,
                    children: [
                      Text(l.parentAreaThisClearsResultsTimeAnd),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          if (!await parentGate(
                                context,
                                gender: ref.read(appProvider).profile?.gender,
                              ) ||
                              !context.mounted) {
                            return;
                          }
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialog) => AlertDialog(
                              title: Text(l.parentAreaClearAllProgress),
                              content: Text(l.parentAreaThisCannotBeUndone),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialog).pop(false),
                                  child: Text(l.parentAreaCancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialog).pop(true),
                                  child: Text(l.parentAreaClearProgress),
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
                              if (context.mounted) {
                                showSaveError(context, error, stack);
                              }
                            }
                          }
                        },
                        child: Text(l.parentAreaResetWithConfirmation),
                      ),
                    ],
                  ),
                if (_tab == 1 && _needsRecovery(data))
                  ParentSection(
                    title: l.parentAreaDataNeedingAttention,
                    children: [
                      Text(
                        key: const ValueKey('recovery-summary'),
                        [
                          l.parentAreaRecoveryAffected(
                            data.quarantinedChildren.length,
                          ),
                          if (ref.read(storeProvider).recovery ==
                              StorageRecovery.restoredFromBackup)
                            l.parentAreaRecoveryRestored,
                          l.parentAreaRecoveryAdvice,
                        ].join(' '),
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
                                    content: Text(l.parentAreaDataCopied),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded),
                            label: Text(l.parentAreaCopyTheData),
                          ),
                          OutlinedButton(
                            key: const ValueKey('discard-damaged'),
                            onPressed: () => _discardDamaged(context, l),
                            child: Text(l.parentAreaDeleteDamagedCopies),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_tab == 1)
                  ParentSection(
                    title: l.parentAreaDiagnostics,
                    children: [
                      Text(l.parentAreaIfSavingOrSoundGoes),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('copy-diagnostics'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: AppLog.export()),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.parentAreaLogCopied)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(l.parentAreaCopyLog),
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
