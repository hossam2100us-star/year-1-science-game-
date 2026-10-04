// Read-only static server for the prebuilt web preview (audit use only).
import 'dart:io';
const types = {'.html':'text/html; charset=utf-8','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.webp':'image/webp','.ttf':'font/ttf','.otf':'font/otf','.wav':'audio/wav','.svg':'image/svg+xml','.css':'text/css','.bin':'application/octet-stream','.frag':'application/octet-stream'};
Future<void> main(List<String> a) async {
  final root = Directory(a[0]).absolute.path;
  final s = await HttpServer.bind(InternetAddress.loopbackIPv4, int.parse(a[1]));
  await for (final r in s) {
    var p = Uri.decodeComponent(r.uri.path); if (p == '/') p = '/index.html';
    final f = File('$root$p');
    if (p.contains('..') || !f.existsSync()) { r.response..statusCode = 404..close(); continue; }
    final ext = p.contains('.') ? p.substring(p.lastIndexOf('.')) : '';
    r.response.headers..set('Content-Type', types[ext] ?? 'application/octet-stream')..set('Cache-Control','no-store');
    await r.response.addStream(f.openRead()); await r.response.close();
  }
}
