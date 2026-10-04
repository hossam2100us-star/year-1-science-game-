import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostics/app_log.dart';
import 'diagnostics/failure.dart';
import 'providers.dart';

/// Logs a failed save and tells the user what actually went wrong.
void showSaveError(
  BuildContext context,
  Object error,
  StackTrace stack, {
  String area = 'save',
}) {
  final kind = classifyFailure(error);
  AppLog.error(area, 'Save failed (${kind.name})', error, stack);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(saveFailureMessage(kind))));
}

/// A heading that never wraps mid-word on a narrow screen: it ends with an
/// ellipsis and the full text is available on long-press and to screen
/// readers (AUD-018).
class FittedTitle extends StatelessWidget {
  const FittedTitle(this.text, {super.key, this.style, this.maxLines = 1});
  final String text;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: text,
    excludeFromSemantics: true,
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      softWrap: maxLines > 1,
    ),
  );
}

class StoryPanel extends ConsumerStatefulWidget {
  const StoryPanel({
    super.key,
    required this.text,
    this.children = const [],
    this.autoSpeak = true,
  });
  final String text;
  final List<Widget> children;
  final bool autoSpeak;
  @override
  ConsumerState<StoryPanel> createState() => _StoryPanelState();
}

class _StoryPanelState extends ConsumerState<StoryPanel> {
  void _speak() => ref.read(narrationProvider).speak(widget.text);
  @override
  void initState() {
    super.initState();
    if (widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak();
      });
    }
  }

  @override
  void didUpdateWidget(covariant StoryPanel old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _speak();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
        width: 2,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          onPressed: _speak,
          tooltip: 'Listen again',
          icon: const Icon(Icons.volume_up_rounded, size: 30),
        ),
        ...widget.children,
      ],
    ),
  );
}

class AdventurePage extends StatelessWidget {
  const AdventurePage({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.padding = 24,
    this.controller,
  });
  final Widget child;
  final double maxWidth, padding;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFCCD8DA),
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
              if (selected) const Icon(Icons.check_circle_rounded, size: 26),
            ],
          ),
        ),
      ),
    ),
  );
}
