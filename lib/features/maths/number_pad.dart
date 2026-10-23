import 'package:flutter/material.dart';

/// Written answers for Maths worksheet questions: the child writes the
/// number (or a whole number sentence) with big keys instead of choosing
/// from three answers, as on a worksheet.

const _blue = Color(0xFF2170B5);
const _review = Color(0xFFC0392B);

/// Digits 0–9 and delete, in two rows on a wide screen or a 3 × 4 grid on
/// a phone. [onKey] gets a digit, or `del`.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onKey, this.locked = false});
  final ValueChanged<String> onKey;
  final bool locked;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'del',
  ];

  Widget _key(BuildContext context, String key, double size) => SizedBox(
    width: size,
    height: size * .82,
    child: FilledButton.tonal(
      key: ValueKey('number-key-$key'),
      onPressed: locked ? null : () => onKey(key),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: key == 'del'
          ? Icon(
              Icons.backspace_outlined,
              size: size * .38,
              semanticLabel: 'Delete',
            )
          : Text(
              key,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: size * .44,
                fontWeight: FontWeight.w600,
              ),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Two rows on a wide screen, three beside a picture, four on a phone.
      final columns = box.maxWidth >= 560
          ? 6
          : box.maxWidth >= 300
          ? 4
          : 3;
      final size = ((box.maxWidth - (columns - 1) * 10) / columns).clamp(
        52.0,
        columns == 6 ? 78.0 : 72.0,
      );
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [for (final k in _keys) _key(context, k, size)],
      );
    },
  );
}

/// One answer box: what the child has written, or "?" while it is empty.
class AnswerBox extends StatelessWidget {
  const AnswerBox({
    super.key,
    required this.text,
    this.focused = false,
    this.review = false,
    this.onTap,
    this.width = 96,
  });
  final String text;
  final bool focused, review;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    selected: focused,
    label: text.isEmpty ? 'Empty box' : text,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: review
                ? _review
                : focused
                ? _blue
                : const Color(0xFFB9C7D3),
            width: focused || review ? 4 : 2,
          ),
        ),
        child: Text(
          text.isEmpty ? '?' : text,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: text.isEmpty
                ? const Color(0xFFB9C7D3)
                : const Color(0xFF223D50),
          ),
        ),
      ),
    ),
  );
}

/// The answer to a worksheet question: a box and the number pad.
class WrittenNumber extends StatelessWidget {
  const WrittenNumber({
    super.key,
    required this.value,
    required this.onChanged,
    this.locked = false,
    this.review = false,
    this.onSay,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final bool locked, review;
  final ValueChanged<String>? onSay;

  void _key(String key) {
    final next = key == 'del'
        ? (value.isEmpty ? '' : value.substring(0, value.length - 1))
        : (value.length >= 2
              ? value
              : value == '0'
              ? key
              : value + key);
    if (next == value) return;
    onChanged(next);
    if (next.isNotEmpty) onSay?.call(next);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnswerBox(
        key: const ValueKey('written-answer'),
        text: value,
        focused: !locked,
        review: review,
      ),
      const SizedBox(height: 14),
      NumberPad(onKey: _key, locked: locked),
    ],
  );
}

/// A number sentence to complete: number, + or −, number, =, result. A tap
/// on a box chooses where the number pad writes; choosing the sign moves on
/// to the second number.
class NumberSentence extends StatefulWidget {
  const NumberSentence({
    super.key,
    required this.slots,
    required this.onChanged,
    this.locked = false,
    this.review = const {},
    this.onSay,
  });
  final Map<String, String> slots;
  final ValueChanged<Map<String, String>> onChanged;
  final bool locked;
  final Set<String> review;
  final ValueChanged<String>? onSay;

  @override
  State<NumberSentence> createState() => _NumberSentenceState();
}

class _NumberSentenceState extends State<NumberSentence> {
  late String _focus = _firstEmpty() ?? 'a';

  String? _firstEmpty() =>
      ['a', 'b', 'c'].where((k) => (widget.slots[k] ?? '').isEmpty).firstOrNull;

  String _at(String key) => widget.slots[key] ?? '';

  void _write(String key, String value) =>
      widget.onChanged({...widget.slots, key: value});

  void _key(String key) {
    final value = _at(_focus);
    final next = key == 'del'
        ? (value.isEmpty ? '' : value.substring(0, value.length - 1))
        : (value.length >= 2
              ? value
              : value == '0'
              ? key
              : value + key);
    if (next == value) return;
    _write(_focus, next);
    if (next.isNotEmpty) widget.onSay?.call(next);
  }

  void _sign(String op) {
    _write('op', op);
    widget.onSay?.call(op == '+' ? 'plus' : 'minus');
    if (_at('b').isEmpty) setState(() => _focus = 'b');
  }

  Widget _box(String key) => AnswerBox(
    key: ValueKey('sentence-$key'),
    text: _at(key),
    focused: !widget.locked && _focus == key,
    review: widget.review.contains(key),
    width: 84,
    onTap: widget.locked ? null : () => setState(() => _focus = key),
  );

  Widget _signButton(String op) {
    final chosen = _at('op') == op;
    return SizedBox(
      width: 64,
      height: 60,
      child: OutlinedButton(
        key: ValueKey('sentence-op-$op'),
        onPressed: widget.locked ? null : () => _sign(op),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: chosen ? const Color(0xFFD7E8F7) : Colors.white,
          side: BorderSide(
            color: widget.review.contains('op') ? _review : _blue,
            width: chosen ? 4 : 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          op == '-' ? '−' : '+',
          style: const TextStyle(fontFamily: 'Fredoka', fontSize: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _box('a'),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _signButton('+'),
              const SizedBox(height: 6),
              _signButton('-'),
            ],
          ),
          _box('b'),
          const Text(
            '=',
            style: TextStyle(fontFamily: 'Fredoka', fontSize: 40),
          ),
          _box('c'),
        ],
      ),
      const SizedBox(height: 14),
      NumberPad(onKey: _key, locked: widget.locked),
    ],
  );
}
