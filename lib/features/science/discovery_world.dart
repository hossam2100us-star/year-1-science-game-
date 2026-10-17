import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/lesson.dart';
import '../../core/touch_cue.dart';
import '../biology/illustrated_art.dart';
import 'science_picture.dart';

/// Shared exploration models. Taps discover; changing focus alone never does.
///
/// Teacher review 4: a tap anywhere on the picture discovers (children tap
/// the picture, not the small marker), the marker sits on the picture, a
/// visited item shows a check, and each scene fits a 1280×800 tablet
/// together with its name and the Next button.
class DiscoveryWorld extends StatelessWidget {
  const DiscoveryWorld({
    super.key,
    required this.step,
    required this.index,
    required this.onFocus,
    required this.onDiscover,
    this.discovered = const {},
  });
  final LessonStep step;
  final int index;
  final ValueChanged<int> onFocus;
  final ValueChanged<String> onDiscover;
  final Set<String> discovered;

  /// The height the app really has: the screen without the status and
  /// navigation bars (a 1280×800 tablet leaves about 716).
  /// Read from the window, not MediaQuery: the lesson page sits in a
  /// SafeArea, which hides the bars from MediaQuery below it.
  static double usableHeight(BuildContext context) {
    final view = View.of(context);
    return (view.physicalSize.height - view.padding.top - view.padding.bottom) /
        view.devicePixelRatio;
  }

  /// Picture height that leaves room for the rest of the activity (the
  /// safety rules also show the rule chips above the picture).
  static double sceneHeight(BuildContext context) =>
      (usableHeight(context) * .25).clamp(150.0, 290.0);
  static double waterHeight(BuildContext context) =>
      (usableHeight(context) * .36).clamp(150.0, 400.0);

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
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: discovered.contains(item.id)
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xE6FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Color(0xFF437A69),
                  ),
                )
              : const TouchCue(),
        ),
      ),
    ),
  );

  Widget safety(BuildContext context) {
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
        const SizedBox(height: 8),
        // The rule's name sits beside the picture (the panel is narrow), so
        // the picture, the name and Next fit a tablet screen together.
        SizedBox(
          height: sceneHeight(context),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: GestureDetector(
                  key: const ValueKey('safety-picture'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDiscover(current.id),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        // The socket rule has its own picture: no hand is
                        // near the socket, on one whole wall (teacher
                        // reviews 4 and 6). The other two
                        // rules are panels of the shared picture.
                        child: index == 0
                            ? const IllustratedArt(
                                asset: 'electric-safety-socket-v4.webp',
                              )
                            : IllustratedArt(
                                asset: 'electric-safety-v1.webp',
                                crop: const [
                                  Rect.fromLTWH(.306, 0, .369, 1),
                                  Rect.fromLTWH(.68, 0, .32, 1),
                                ][index - 1],
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: Center(child: touch(current)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  current.label,
                  key: const ValueKey('safety-rule-name'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The place nearest to a tap on the water picture.
  String _nearestPlace(Offset tap, Size size) {
    String? best;
    var bestDistance = double.infinity;
    for (final item in step.options) {
      final p = _waterPositions[item.id]!;
      final d = (Offset(p.dx * size.width, p.dy * size.height) - tap).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = item.id;
      }
    }
    return best!;
  }

  Widget water(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, outer) {
          final width = math.min(outer.maxWidth, waterHeight(context) * 2);
          final size = Size(width, width / 2);
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox.fromSize(
                size: size,
                child: GestureDetector(
                  key: const ValueKey('water-picture'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      onDiscover(_nearestPlace(details.localPosition, size)),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: IllustratedArt(asset: 'water-world-v1.webp'),
                      ),
                      for (final item in step.options)
                        Positioned(
                          left: size.width * _waterPositions[item.id]!.dx - 24,
                          top: size.height * _waterPositions[item.id]!.dy - 24,
                          child: touch(item),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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

  /// The old three-column model, kept for narrow screens where a huge Sun
  /// would leave no room for Earth and the Moon.
  Widget spaceColumns() => ClipRRect(
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
  );

  /// Teacher review 4: the Sun is drawn very large and partly outside the
  /// picture, so children see how much bigger it is than Earth; tapping a
  /// body discovers it, like its marker.
  Widget space(BuildContext context) => LayoutBuilder(
    builder: (context, outer) {
      if (outer.maxWidth < 560) return spaceColumns();
      final w = outer.maxWidth;
      // Short enough that the caption and Next fit under it on a tablet.
      final h = math.max(
        200.0,
        math.min(math.min(360.0, w * .48), usableHeight(context) * .32),
      );
      final sun = h * 1.5;
      final visibleSun = sun * .45;
      final x0 = visibleSun + 24;
      final byId = {for (final item in step.options) item.id: item};
      const labelStyle = TextStyle(color: Colors.white, fontSize: 18);
      Widget label(PictureItem item) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xB30B132C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Text(item.label, style: labelStyle),
        ),
      );
      Widget tappable(PictureItem item, Widget child) => GestureDetector(
        key: ValueKey('space-body-${item.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onDiscover(item.id),
        child: child,
      );
      // A body's name and marker, centred under it.
      Widget caption(PictureItem item, double centreX, double top) =>
          Positioned(
            left: centreX - 90,
            width: 180,
            top: top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [label(item), const SizedBox(height: 4), touch(item)],
            ),
          );
      Widget body(PictureItem item, double size, Offset centre) => Positioned(
        left: centre.dx - size / 2,
        top: centre.dy - size / 2,
        width: size,
        height: size,
        child: tappable(
          item,
          Center(child: SciencePicture(item.art, height: size)),
        ),
      );
      final earthSize = h * .30, moonSize = h * .13;
      final earth = Offset(x0 + (w - x0) * .38, h * .40);
      final moon = Offset(x0 + (w - x0) * .70, h * .30);
      return ClipRRect(
        key: const ValueKey('space-discovery-model'),
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: h,
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
              Positioned(
                left: visibleSun - sun,
                top: (h - sun) / 2,
                width: sun,
                height: sun,
                child: tappable(
                  byId['sun']!,
                  Center(child: SciencePicture(byId['sun']!.art, height: sun)),
                ),
              ),
              body(byId['earth']!, earthSize, earth),
              body(byId['moon']!, moonSize, moon),
              caption(byId['sun']!, visibleSun / 2, h * .42),
              caption(byId['earth']!, earth.dx, earth.dy + earthSize / 2 + 8),
              caption(byId['moon']!, moon.dx, moon.dy + moonSize / 2 + 8),
            ],
          ),
        ),
      );
    },
  );

  // The "not to scale" note is for parents (unit report), not children.
  Widget spaceModel(BuildContext context) => Column(
    children: [
      space(context),
      const SizedBox(height: 8),
      const Text(
        'Earth travels around the Sun. The Moon travels around Earth.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => step.id.startsWith('unit_07')
      ? safety(context)
      : step.id.startsWith('unit_08')
      ? water(context)
      : spaceModel(context);
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
