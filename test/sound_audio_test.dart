import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

List<int> samples(String name) {
  final bytes = File('assets/audio/$name.wav').readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
  expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE');
  List<int>? pcm;
  var formatFound = false;
  for (var offset = 12; offset + 8 <= bytes.length;) {
    final chunk = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    expect(start + length, lessThanOrEqualTo(bytes.length));
    if (chunk == 'fmt ') {
      expect(data.getUint16(start, Endian.little), 1);
      expect(data.getUint16(start + 2, Endian.little), 1);
      expect(data.getUint32(start + 4, Endian.little), 22050);
      expect(data.getUint16(start + 14, Endian.little), 16);
      formatFound = true;
    } else if (chunk == 'data') {
      expect(length.isEven, true);
      pcm = [
        for (var i = start; i < start + length; i += 2)
          data.getInt16(i, Endian.little),
      ];
    }
    offset = start + length + (length.isOdd ? 1 : 0);
  }
  expect(formatFound, true);
  expect(pcm, isNotNull);
  expect(pcm, isNotEmpty);
  return pcm!;
}

void main() {
  test('Feather box is silent while the stone box is audible', () {
    expect(samples('feather').every((sample) => sample == 0), true);
    expect(samples('stone').any((sample) => sample.abs() > 1000), true);
  });
}
