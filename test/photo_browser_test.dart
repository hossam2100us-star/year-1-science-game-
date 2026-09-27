import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:science_adventure/core/photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final dimensions in [
    (256, 1024, 128, 512),
    (1024, 256, 512, 128),
    (64, 64, 64, 64),
  ]) {
    test('Photo import preserves aspect ratio: $dimensions', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff3478ac), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final source = await picture.toImage(dimensions.$1, dimensions.$2);
      final bytes = await source.toByteData(format: ui.ImageByteFormat.png);
      source.dispose();
      picture.dispose();
      final result = await sanitizePhoto(
        XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png'),
      );
      final codec = await ui.instantiateImageCodec(result);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, dimensions.$3);
      expect(frame.image.height, dimensions.$4);
      frame.image.dispose();
      codec.dispose();
    });
  }
}
