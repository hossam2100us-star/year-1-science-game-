import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:science_adventure/core/photo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'A portrait is bounded and imported without private image metadata',
    () async {
      final input = await File('test/fixtures/portrait_with_metadata.png')
          .readAsBytes();
      expect(latin1.decode(input), contains('PRIVATE_TEST_METADATA'));
      final output = await sanitizePhoto(
        XFile.fromData(input, mimeType: 'image/png'),
      );
      expect(latin1.decode(output), isNot(contains('PRIVATE_TEST_METADATA')));
      expect(latin1.decode(output), isNot(contains('GPSLocation')));
      final buffer = await ui.ImmutableBuffer.fromUint8List(output);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      expect(descriptor.width, 128);
      expect(descriptor.height, 512);
      descriptor.dispose();
      buffer.dispose();
    },
  );
  test(
    'Broken images return an error instead of replacing an avatar',
    () async {
      expect(
        () => sanitizePhoto(XFile.fromData(utf8.encode('not an image'))),
        throwsA(anything),
      );
    },
  );
}
