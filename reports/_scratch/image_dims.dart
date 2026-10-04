import 'dart:io';
import 'dart:typed_data';
List<int> dims(String p) {
  final d = File(p).openSync()..setPositionSync(0);
  final b = Uint8List.fromList(d.readSync(40)); d.closeSync();
  final bd = ByteData.sublistView(b);
  if (p.endsWith('.png')) return [bd.getUint32(16), bd.getUint32(20)];
  final tag = String.fromCharCodes(b.sublist(12, 16));
  if (tag == 'VP8X') return [(b[24] | b[25] << 8 | b[26] << 16) + 1, (b[27] | b[28] << 8 | b[29] << 16) + 1];
  if (tag == 'VP8 ') return [bd.getUint16(26, Endian.little) & 0x3fff, bd.getUint16(28, Endian.little) & 0x3fff];
  final v = bd.getUint32(21, Endian.little); return [(v & 0x3fff) + 1, ((v >> 14) & 0x3fff) + 1];
}
void main() {
  final used = RegExp(r'assets/images/([\w.-]+)').allMatches(File('pubspec.yaml').readAsStringSync()).map((m) => m[1]!).toList();
  var dec = 0.0, file = 0;
  for (final u in used) {
    final p = 'assets/images/$u'; final x = dims(p); final mb = x[0] * x[1] * 4 / 1048576; dec += mb;
    final s = File(p).lengthSync(); file += s;
    print('${u.padRight(30)} ${x[0]}x${x[1]}  file=${(s / 1048576).toStringAsFixed(1)}MB decoded=${mb.toStringAsFixed(0)}MB');
  }
  print('bundled=${used.length} fileMB=${(file / 1048576).toStringAsFixed(1)} decodedMB=${dec.toStringAsFixed(0)}');
}
