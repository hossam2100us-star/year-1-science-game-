import 'package:flutter/material.dart';

import '../maths/maths_visual.dart';
import 'english_art.dart';

const _ink = Color(0xFF223D50);
const _line = Color(0xFFB9C7D3);
const _outline = Color(0xFFD9822B);

/// What an English question shows above its answers, described by lesson
/// JSON (`englishVisual`). Like the Maths pictures, it never shows which
/// answer is right.
class EnglishVisual extends StatelessWidget {
  const EnglishVisual({super.key, required this.data});
  final Map<String, dynamic> data;

  static const _big = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 32,
    color: _ink,
  );

  @override
  Widget build(BuildContext context) => switch (data['type']) {
    'sentence' => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        '${data['text']}',
        key: const ValueKey('english-sentence'),
        textAlign: TextAlign.center,
        style: _big,
      ),
    ),
    'story' => _Story(data: data),
    'picture' => _Pictures(
      items: [for (final item in data['items'] as List) '$item'],
      height: (data['height'] as num?)?.toDouble() ?? 120,
    ),
    'number' => Semantics(
      label: 'The number ${data['value']}',
      child: Text(
        '${data['value']}',
        textAlign: TextAlign.center,
        style: _big.copyWith(fontSize: 72),
      ),
    ),
    'alphabet' => _Alphabet(letters: '${data['letters']}'),
    'bookPage' => _BookPage(highlight: '${data['highlight']}'),
    'chart' => MathsVisual(data: data),
    _ => const SizedBox.shrink(),
  };
}

class _Pictures extends StatelessWidget {
  const _Pictures({required this.items, required this.height});
  final List<String> items;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: items.join(', '),
    image: true,
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        for (final item in items)
          if (hasEnglishPicture(item)) EnglishPicture(item, height: height),
      ],
    ),
  );
}

/// A story's title and a line about it, with its picture.
class _Story extends StatelessWidget {
  const _Story({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final picture = data['picture'] as String?;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${data['title']}',
          style: const TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 28,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text('${data['text']}', style: const TextStyle(fontSize: 20)),
      ],
    );
    return Row(
      children: [
        if (picture != null && hasEnglishPicture(picture)) ...[
          EnglishPicture(picture, height: 110),
          const SizedBox(width: 16),
        ],
        Expanded(child: text),
      ],
    );
  }
}

/// A few letters of the alphabet in boxes, with `_` for the missing one.
class _Alphabet extends StatelessWidget {
  const _Alphabet({required this.letters});
  final String letters;

  @override
  Widget build(BuildContext context) => Semantics(
    label: letters.split('').map((l) => l == '_' ? 'gap' : l).join(', '),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final letter in letters.split(''))
          Container(
            width: 64,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: letter == '_' ? const Color(0xFFFFF1D5) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: letter == '_' ? _outline : _line,
                width: letter == '_' ? 3 : 2,
              ),
            ),
            child: Text(
              letter == '_' ? '?' : letter,
              style: EnglishVisual._big.copyWith(
                fontSize: 38,
                color: letter == '_' ? _outline : _ink,
              ),
            ),
          ),
      ],
    ),
  );
}

/// A page of an information book (unit 9): heading, picture, label and
/// caption, a fact box and text. The part a question asks about has a thick
/// orange outline.
class _BookPage extends StatelessWidget {
  const _BookPage({required this.highlight});
  final String highlight;

  BoxDecoration _box(String part, {Color fill = Colors.white}) => BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: highlight == part ? _outline : _line,
      width: highlight == part ? 4 : 1.5,
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'A page of an information book. The $highlight has an outline.',
    child: Center(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const ValueKey('page-heading'),
              padding: const EdgeInsets.all(6),
              decoration: _box('heading'),
              child: const Text(
                'Reduce, Reuse, Recycle',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 22),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 56),
                            child: EnglishPicture('bottle', height: 80),
                          ),
                          Positioned(
                            right: 0,
                            top: 22,
                            child: Container(
                              key: const ValueKey('page-label'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: _box('label'),
                              // A short line points from the label to the
                              // bottle (the fonts have no arrow).
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 16, height: 2, color: _ink),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'lid',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        key: const ValueKey('page-caption'),
                        padding: const EdgeInsets.all(4),
                        decoration: _box('caption'),
                        child: const Text(
                          'A bottle in the sea.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: _box('fact box', fill: const Color(0xFFE7F3EA)),
                    child: const Text(
                      'Fact! Plastic takes hundreds of years to break down.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final width in const [1.0, .9, .7])
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: width,
                child: Container(
                  height: 7,
                  margin: const EdgeInsets.only(bottom: 6),
                  color: const Color(0xFFDDE4EA),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
