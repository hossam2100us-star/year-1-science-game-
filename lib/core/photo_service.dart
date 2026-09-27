import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_cache_stub.dart' if (dart.library.io) 'photo_cache_native.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  Future<Uint8List?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _consume(file);
  }

  Future<Uint8List?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final lost = await _picker.retrieveLostData();
    if (lost.exception != null) throw lost.exception!;
    if (lost.files == null || lost.files!.isEmpty) return null;
    return _consume(lost.files!.first);
  }

  Future<Uint8List> _consume(XFile file) async {
    try {
      return await sanitizePhoto(file);
    } finally {
      await removeTemporaryPhoto(file.path);
    }
  }
}

/// Decode a bounded image and persist pixels only, never metadata or a source URI.
Future<Uint8List> sanitizePhoto(XFile file) async {
  if (await file.length() > 20 * 1024 * 1024)
    throw const FormatException('Image too large');
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    await file.readAsBytes(),
  );
  ui.Codec? codec;
  try {
    // This API owns the buffer and exposes dimensions on web as well as mobile.
    // ImageDescriptor.width/height are unsupported for encoded web images.
    codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        if (width * height > 60000000)
          throw const FormatException('Image too large');
        final scale = math.min(1.0, 512 / math.max(width, height));
        return ui.TargetImageSize(
          width: math.max(1, (width * scale).round()),
          height: math.max(1, (height * scale).round()),
        );
      },
    );
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > 3 * 1024 * 1024)
        throw const FormatException('Unsupported image');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec?.dispose();
  }
}
