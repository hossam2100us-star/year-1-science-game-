import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import '../biology/illustrated_art.dart';
import 'science_picture.dart';

/// Shared exploration models. Taps discover; changing focus alone never does.
class DiscoveryWorld extends StatelessWidget {
  const DiscoveryWorld({
    super.key,
    required this.step,
    required this.index,
    required this.onFocus,
    required this.onDiscover,
  });
  final LessonStep step;
  final int index;
  final ValueChanged<int> onFocus;
  final ValueChanged<String> onDiscover;

  static bool supports(LessonStep step) => const [
    'unit_07.step.001',
    'unit_08.step.001',
    'unit_09.step.001',
  ].contains(step.id);

  Widget touch(PictureItem item) => Semantics(
    label: 'Explore ${item.label}',
    button: true,
    child: InkWell(
      key: ValueKey('science-item-${item.id}'),
      onTap: () => onDiscover(item.id),
      borderRadius: BorderRadius.circular(24),
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: TouchCue()),
      ),
    ),
  );

  Widget safety() {
    final current = step.options[index];
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < step.options.length; i++)
              ChoiceChip(
                key: ValueKey('safety-focus-${step.options[i].id}'),
                label: Text(step.options[i].label),
                selected: i == index,
                onSelected: (_) => onFocus(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 290,
          width: double.infinity,
          child: IllustratedArt(
            asset: 'electric-safety-v1.webp',
            crop: const [
              Rect.fromLTWH(0, 0, .304, 1),
              Rect.fromLTWH(.306, 0, .369, 1),
              Rect.fromLTWH(.68, 0, .32, 1),
            ][index],
          ),
        ),
        Text(
          current.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        touch(current),
      ],
    );
  }

  Widget water() => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 2,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                const Positioned.fill(
                  child: IllustratedArt(asset: 'water-world-v1.webp'),
                ),
                for (final item in step.options)
                  Positioned(
                    left: box.maxWidth * _waterPositions[item.id]!.dx - 24,
                    top: box.maxHeight * _waterPositions[item.id]!.dy - 24,
                    child: touch(item),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        step.options[index].label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Compare still water and flowing water.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget space() => Column(
    children: [
      ClipRRect(
        key: const ValueKey('space-discovery-model'),
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, box) {
            const labelStyle = TextStyle(color: Colors.white, fontSize: 18);
            final ordered = [
              for (final id in ['sun', 'earth', 'moon'])
                step.options.firstWhere((item) => item.id == id),
            ];
            final narrow = box.maxWidth < 216;
            final columnWidth = (box.maxWidth - 40) / 3;
            var labelHeight = 0.0;
            if (!narrow) {
              for (final item in step.options) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: item.label,
                    style: DefaultTextStyle.of(context).style.merge(labelStyle),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: columnWidth);
                labelHeight = math.max(labelHeight, painter.height);
                painter.dispose();
              }
            }
            final height = math.max(240.0, math.min(360.0, box.maxWidth * .48));
            // Reserve the measured label and the full 48 dp touch target before
            // sizing the artwork. Large text cannot push a cue below the model.
            final artHeight = math.max(
              24.0,
              math.min(
                math.min(190.0, columnWidth / 1.25),
                height - 24 - labelHeight - 64,
              ),
            );
            Widget body(PictureItem item) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: artHeight,
                  child: Center(
                    child: SciencePicture(
                      item.art,
                      height: artHeight * _spaceRelativeSizes[item.id]!,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: labelHeight + 4,
                  child: Center(
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                touch(item),
              ],
            );
            final bodies = narrow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in ordered)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: box.maxWidth * .25,
                                child: SciencePicture(
                                  item.art,
                                  height:
                                      box.maxWidth *
                                      .2 *
                                      _spaceRelativeSizes[item.id]!,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: labelStyle,
                                ),
                              ),
                              touch(item),
                            ],
                          ),
                        ),
                    ],
                  )
                : SizedBox(
                    height: height - 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var i = 0; i < ordered.length; i++) ...[
                          if (i != 0) const SizedBox(width: 8),
                          Expanded(child: body(ordered[i])),
                        ],
                      ],
                    ),
                  );
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: narrow ? 0 : height),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF192B50), Color(0xFF070D20)],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: CustomPaint(painter: _Stars())),
                  Padding(padding: const EdgeInsets.all(12), child: bodies),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Model: sizes and distances are not to scale.',
        textAlign: TextAlign.center,
      ),
      const Text(
        'Earth travels around the Sun. The Moon travels around Earth.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => step.id.startsWith('unit_07')
      ? safety()
      : step.id.startsWith('unit_08')
      ? water()
      : space();
}

const _waterPositions = {
  'pond': Offset(.15, .67),
  'stream': Offset(.16, .23),
  'lake': Offset(.37, .40),
  'river': Offset(.57, .59),
  'ocean': Offset(.87, .34),
};
const _spaceRelativeSizes = {'sun': 1.0, 'earth': .74, 'moon': .46};

class _Stars extends CustomPainter {
  const _Stars();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xBBD7E6FF);
    for (var i = 0; i < 45; i++) {
      canvas.drawCircle(
        Offset(
          size.width * ((i * 37 % 101) / 101),
          size.height * ((i * 53 % 97) / 97),
        ),
        i % 4 == 0 ? 2 : 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Stars oldDelegate) => false;
}
