import 'dart:io';
import 'dart:typed_data';

/// Review screenshots are opt-in (AUD-010):
///
///     flutter test --dart-define=REVIEW_IMAGES=true
///
/// They go to the git-ignored build/review/ folder, so a normal test run
/// writes nothing. Pixel comparisons live in the golden tests instead.
const writeReviewImages = bool.fromEnvironment('REVIEW_IMAGES');

Future<void> saveReviewImage(String name, ByteData? png) async {
  if (!writeReviewImages || png == null) return;
  final file = File('build/review/$name');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(png.buffer.asUint8List());
}
