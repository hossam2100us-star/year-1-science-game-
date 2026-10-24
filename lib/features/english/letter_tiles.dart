import 'package:flutter/material.dart';

const _blue = Color(0xFF2170B5);
const _review = Color(0xFFC0392B);
const _ink = Color(0xFF223D50);

/// A written English answer: the word so far ("tr" + what the child
/// wrote), a button that reads the whole word aloud, and big letter tiles.
/// Each tile is used once, as on a worksheet with cut-out letters; delete
/// gives the last letter back.
///
/// The voice reads whole words only (owner decision, 23 October 2026: no
/// isolated letter sounds), so the tiles themselves are silent.
class WrittenWord extends StatelessWidget {
  const WrittenWord({
    super.key,
    required this.value,
    required this.letters,
    required this.onChanged,
    this.locked = false,
    this.review = false,
    this.onSay,
  });

  /// What the child has written.
  final String value;

  /// The step's `letters`: `before`, `after`, `tiles` and `say`.
  final Map<String, dynamic> letters;
  final ValueChanged<String> onChanged;
  final bool locked, review;
  final ValueChanged<String>? onSay;

  List<String> get _tiles => [for (final t in letters['tiles'] as List) '$t'];

  /// The tiles already in the word: for each letter written, the first
  /// tile with that letter that is not used yet.
  Set<int> get _used {
    final used = <int>{};
    final tiles = _tiles;
    for (final letter in value.split('')) {
      for (var i = 0; i < tiles.length; i++) {
        if (tiles[i] == letter && !used.contains(i)) {
          used.add(i);
          break;
        }
      }
    }
    return used;
  }

  Widget _tile(int index, String letter, bool used) => SizedBox(
    width: 68,
    height: 68,
    child: FilledButton.tonal(
      key: ValueKey('letter-tile-$index'),
      onPressed: locked || used ? null : () => onChanged(value + letter),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 34,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final before = '${letters['before'] ?? ''}';
    final after = '${letters['after'] ?? ''}';
    final say = letters['say'] as String?;
    final used = _used;
    const word = TextStyle(
      fontFamily: 'Fredoka',
      fontSize: 44,
      fontWeight: FontWeight.w600,
      color: _ink,
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Semantics(
                label: value.isEmpty
                    ? '$before, then a gap$after'
                    : '$before$value$after',
                child: Container(
                  key: const ValueKey('written-word'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: review ? _review : _blue,
                      width: review ? 4 : 3,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        style: word,
                        children: [
                          TextSpan(text: before),
                          TextSpan(
                            text: value.isEmpty ? ' _ ' : value,
                            style: const TextStyle(
                              color: _blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: after),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (say != null && onSay != null) ...[
              const SizedBox(width: 10),
              IconButton.filledTonal(
                key: const ValueKey('letter-listen'),
                tooltip: 'Listen to the word',
                iconSize: 32,
                onPressed: () => onSay!(say),
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (index, letter) in _tiles.indexed)
              _tile(index, letter, used.contains(index)),
            SizedBox(
              width: 68,
              height: 68,
              child: OutlinedButton(
                key: const ValueKey('letter-delete'),
                onPressed: locked || value.isEmpty
                    ? null
                    : () => onChanged(value.substring(0, value.length - 1)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.backspace_outlined,
                  size: 30,
                  semanticLabel: 'Delete',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
