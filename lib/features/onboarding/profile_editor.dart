import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/mascot.dart';
import '../../core/models.dart';
import '../../core/photo_service.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../parent/parent_gate.dart';
import '../../parent/voice_settings.dart';

class ProfileEditor extends ConsumerStatefulWidget {
  const ProfileEditor({super.key, this.editing = false, this.newChild = false});
  final bool editing, newChild;
  @override
  ConsumerState<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<ProfileEditor> {
  final _name = TextEditingController();
  final _scroll = ScrollController();
  final _photos = PhotoService();
  ChildGender _gender = ChildGender.boy;
  PaletteChoice _palette = PaletteChoice.automatic;
  int _avatar = 0, _step = 0;
  Uint8List? _photo;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    final p = widget.newChild ? null : ref.read(appProvider).profile;
    if (p != null) {
      _name.text = p.name;
      _gender = p.gender;
      _palette = p.palette;
      _avatar = p.avatar;
      _photo = p.photo;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.newChild && ref.read(appProvider).pendingPhoto && mounted) {
        if (await parentGate(context) && mounted) await _recover();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changeStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  ChildProfile get _profile => ChildProfile(
    name: _name.text.trim(),
    gender: _gender,
    avatar: _avatar,
    photo: _photo,
    palette: _palette,
  );
  Future<void> _recover() async {
    setState(() => _busy = true);
    try {
      final photo = await _photos.recover();
      await ref.read(appProvider.notifier).photoPending(false);
      if (mounted)
        setState(() {
          _photo = photo ?? _photo;
          _step = 2;
        });
    } catch (_) {
      if (mounted)
        setState(() => _message = 'Please choose your picture again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    await ref.read(narrationProvider).stop();
    if (!mounted) return;
    if (!widget.editing && !widget.newChild && !await parentGate(context))
      return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!widget.newChild)
        await ref.read(appProvider.notifier).photoPending(true);
      final photo = await _photos.pick();
      if (!widget.newChild)
        await ref.read(appProvider.notifier).photoPending(false);
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (error) {
      if (mounted)
        setState(
          () => _message =
              error is FormatException && error.message == 'Image too large'
              ? 'Picture too large. Choose a smaller picture (under 20 MB).\nالصورة كبيرة جدًا. اختار صورة أصغر من 20 ميجابايت.'
              : 'Could not open this picture. Try a JPG or PNG picture.\nالصورة ما اتفتحتش. جرّب صورة بصيغة JPG أو PNG.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      if (widget.newChild) {
        await ref.read(appProvider.notifier).addChild(_profile);
      } else {
        await ref.read(appProvider.notifier).saveProfile(_profile);
      }
      if ((widget.editing || widget.newChild) && mounted)
        Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showSaveError(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final speech = switch (_step) {
      0 => 'Hello, scientist! What is your first name? Ask a grown-up to help you type. You can also skip.',
      1 => 'Choose boy or girl. Your scientist friend and colours will change with you.',
      _ => 'Choose your picture. Fox, Bunny, or Cat. A grown-up can help you choose your own photo. Then tap Start exploring.',
    };
    ref
        .read(narrationProvider)
        .configure(ref.watch(appProvider).settings, _gender);
    return Theme(
      data: adventureTheme(profile),
      child: Builder(
        builder: (context) => Scaffold(
          body: AdventurePage(
            maxWidth: 1000,
            controller: _scroll,
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.editing)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    Expanded(
                      child: Text(
                        'My little adventure',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    Text(
                      '${_step + 1} / 3',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 28,
                  runSpacing: 20,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScientistOwl(
                          gender: _gender,
                          size: 170,
                          mood: _step == 2 ? OwlMood.happy : OwlMood.idle,
                        ),
                        Text(
                          'Meet ${profile.guideName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text('Your science friend'),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 660),
                      child: StoryPanel(
                        text: speech,
                        children: [
                          if (_step == 0) ...[
                            TextField(
                              key: const ValueKey('childName'),
                              controller: _name,
                              maxLength: 24,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'[\n\r\t]'),
                                ),
                              ],
                              textCapitalization: TextCapitalization.words,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'My first name • اسمي',
                                hintText: 'Your name',
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _changeStep(1),
                            ),
                            const Text(
                              'First name only • الاسم الأول بس',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                              ),
                            ),
                          ],
                          if (_step == 1)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final gender in ChildGender.values)
                                  ChoiceTile(
                                    label: gender == ChildGender.boy
                                        ? 'Boy • ولد'
                                        : 'Girl • بنت',
                                    selected: _gender == gender,
                                    onTap: () =>
                                        setState(() => _gender = gender),
                                    child: ScientistOwl(
                                      gender: gender,
                                      size: 90,
                                    ),
                                  ),
                              ],
                            ),
                          if (_step == 2) ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  ChoiceTile(
                                    label: ['Fox', 'Bunny', 'Cat'][i],
                                    selected: _photo == null && _avatar == i,
                                    onTap: () => setState(() {
                                      _avatar = i;
                                      _photo = null;
                                    }),
                                    child: ChildAvatar(
                                      profile: ChildProfile(avatar: i),
                                      size: 80,
                                    ),
                                  ),
                                ChoiceTile(
                                  label: 'My photo',
                                  selected: _photo != null,
                                  onTap: _pickPhoto,
                                  child: _photo == null
                                      ? const SizedBox.square(
                                          dimension: 80,
                                          child: Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 48,
                                          ),
                                        )
                                      : ChildAvatar(profile: profile, size: 80),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'My photo stays on this device.\nصورتي بتفضل على الجهاز بس.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                              ),
                            ),
                            if (_photo != null)
                              TextButton(
                                onPressed: () => setState(() => _photo = null),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Remove my photo • شيل الصورة'),
                                ),
                              ),
                          ],
                          if (_message != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              if (_step > 0)
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _changeStep(_step - 1),
                                  child: const Text('Back'),
                                ),
                              FilledButton.icon(
                                key: const ValueKey('profileNext'),
                                onPressed: _busy
                                    ? null
                                    : _step < 2
                                    ? () => _changeStep(_step + 1)
                                    : _save,
                                icon: Icon(
                                  _step < 2
                                      ? Icons.arrow_forward_rounded
                                      : Icons.explore_rounded,
                                ),
                                label: Text(
                                  _busy
                                      ? 'Saving…'
                                      : _step == 2
                                      ? (widget.editing
                                            ? 'Save my changes'
                                            : widget.newChild
                                            ? 'Create child profile'
                                            : 'Start exploring')
                                      : _step == 0 && _name.text.trim().isEmpty
                                      ? 'Skip for now'
                                      : 'Next',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const VoiceHelpButton(),
                const Text(
                  'A small adventure. A big world to discover.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
