import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:science_adventure/data/remote/api_client.dart';
import 'package:science_adventure/data/remote/api_errors.dart';

class MemoryTokens implements RefreshTokenStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

const user = {
  'id': '0192f0a0-0000-7000-8000-000000000001',
  'email': 'parent@example.com',
  'emailVerified': true,
  'signInMethods': ['password'],
  'createdAt': '2026-10-09T10:00:00.000Z',
};

Map<String, dynamic> session(
  String access, {
  String? refresh,
  int expiresIn = 900,
}) => {
  'accessToken': access,
  'tokenType': 'Bearer',
  'expiresIn': expiresIn,
  'refreshToken': ?refresh,
  'user': user,
};

http.Response json(
  Object body, [
  int status = 200,
  Map<String, String> headers = const {},
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...headers},
);

http.Response problem(
  int status,
  String code, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode({
    'type': 'urn:x:$code',
    'title': 't',
    'status': status,
    'code': code,
  }),
  status,
  headers: {'content-type': 'application/problem+json', ...headers},
);

/// The [ApiProblem] a call fails with (the test fails if it succeeds).
Future<ApiProblem> problemOf(Future<Object?> call) async {
  try {
    await call;
  } on ApiProblem catch (p) {
    return p;
  }
  throw TestFailure('expected an ApiProblem');
}

void main() {
  late MemoryTokens tokens;
  final requests = <http.Request>[];

  ApiClient client(
    Future<http.Response> Function(http.Request) handler, {
    String platform = 'android',
  }) => ApiClient(
    base: Uri.parse('https://school.example.test'),
    httpClient: MockClient((r) {
      requests.add(r);
      return handler(r);
    }),
    tokens: tokens,
    deviceId: '0192f0a0-0000-7000-8000-00000000000d',
    platform: platform,
  );

  setUp(() {
    tokens = MemoryTokens();
    requests.clear();
  });

  test('signs in, keeps the refresh token in the secure store and the access token in memory', () async {
    final api = client((r) async {
      if (r.url.path == '/api/v1/auth/login') {
        return json(session('A1', refresh: 'R' * 43));
      }
      if (r.url.path == '/api/v1/users/me') {
        expect(r.headers['Authorization'], 'Bearer A1');
        return json(user);
      }
      return problem(404, 'not_found');
    });
    final signedIn = await api.login(
      'parent@example.com',
      'a long password here',
    );
    expect(signedIn.email, 'parent@example.com');
    expect(tokens.value, 'R' * 43);
    final login = jsonDecode(requests.first.body) as Map<String, dynamic>;
    expect(login['deviceId'], '0192f0a0-0000-7000-8000-00000000000d');
    expect(login['platform'], 'android');
    expect((await api.me()).id, user['id']);
  });

  test(
    'renews an expired access token once even when two requests need it',
    () async {
      tokens.value = 'R' * 43;
      var refreshes = 0;
      final api = client((r) async {
        if (r.url.path == '/api/v1/auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(jsonDecode(r.body), {'refreshToken': 'R' * 43});
          return json(session('A2', refresh: 'S' * 43));
        }
        return json(user);
      });
      await Future.wait([api.me(), api.me()]);
      expect(refreshes, 1);
      expect(tokens.value, 'S' * 43);
    },
  );

  test(
    'renews and retries once when the server says the access token expired',
    () async {
      final api = client((r) async {
        switch (r.url.path) {
          case '/api/v1/auth/login':
            return json(session('OLD', refresh: 'R' * 43));
          case '/api/v1/auth/refresh':
            return json(session('NEW', refresh: 'S' * 43));
          default:
            return r.headers['Authorization'] == 'Bearer NEW'
                ? json(user)
                : problem(401, 'token_expired');
        }
      });
      await api.login('parent@example.com', 'a long password here');
      expect((await api.me()).email, 'parent@example.com');
    },
  );

  test(
    'a revoked session signs the device out and forgets the token',
    () async {
      tokens.value = 'R' * 43;
      final api = client((r) async => problem(401, 'session_revoked'));
      await expectLater(api.me(), throwsA(isA<SignedOut>()));
      expect(tokens.value, isNull);
    },
  );

  test('without a saved session, restoring makes no network request', () async {
    final api = client((r) async => fail('no request expected'));
    expect(await api.restore(), isNull);
    expect(requests, isEmpty);
  });

  test('reports problems with their code, detail and Retry-After', () async {
    final api = client(
      (r) async => problem(429, 'rate_limited', headers: {'retry-after': '42'}),
    );
    final error = await problemOf(
      api.register('a@example.com', 'a long password here'),
    );
    expect(error.code, 'rate_limited');
    expect(error.retryAfter, const Duration(seconds: 42));
  });

  test(
    'treats an HTML error page from a proxy as a problem, not a crash',
    () async {
      final api = client(
        (r) async => http.Response('<html>Bad gateway</html>', 502),
      );
      final error = await problemOf(api.forgotPassword('a@example.com'));
      expect(error.code, 'http_502');
    },
  );

  test('turns an unreachable server into a network failure', () async {
    final api = client(
      (r) async => throw http.ClientException('Connection refused'),
    );
    await expectLater(
      api.forgotPassword('a@example.com'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('on the web, renews with the cookie and the CSRF header, never a token in the body', () async {
    var refreshes = 0;
    final api = client((r) async {
      if (r.url.path == '/api/v1/auth/refresh') {
        refreshes++;
        expect(r.headers['X-CSRF-Protection'], '1');
        expect(jsonDecode(r.body), isEmpty);
        // Another tab renewed the shared cookie a moment ago.
        return refreshes == 1
            ? problem(409, 'refresh_superseded')
            : json(session('W1'));
      }
      return json(user);
    }, platform: 'web');
    expect(await api.restore(), isNotNull);
    expect(refreshes, 2);
    expect(tokens.value, isNull);
  });

  test('sends sync pushes with this device and reads pull pages', () async {
    tokens.value = 'R' * 43;
    final api = client((r) async {
      switch (r.url.path) {
        case '/api/v1/auth/refresh':
          return json(session('A', refresh: 'S' * 43));
        case '/api/v1/sync/push':
          final body = jsonDecode(r.body) as Map<String, dynamic>;
          expect(body['deviceId'], '0192f0a0-0000-7000-8000-00000000000d');
          return json({
            'results': [
              {
                'mutationId': (body['mutations'] as List).first['mutationId'],
                'status': 'applied',
                'changeSeq': 7,
              },
            ],
          });
        default:
          expect(r.url.queryParameters, {'since': '7', 'limit': '200'});
          return json({'changes': <Object>[], 'cursor': 7, 'hasMore': false});
      }
    });
    final results = await api.push([
      {
        'mutationId': '0192f0a0-0000-7000-8000-0000000000aa',
        'entity': 'child',
        'op': 'delete',
        'id': user['id'],
      },
    ]);
    expect(results.single['status'], 'applied');
    final page = await api.pull(7);
    expect(page.cursor, 7);
    expect(page.hasMore, isFalse);
  });

  test('gives up after the timeout instead of hanging', () async {
    final api = ApiClient(
      base: Uri.parse('https://school.example.test'),
      httpClient: MockClient((r) => Completer<http.Response>().future),
      tokens: tokens,
      deviceId: 'd',
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      api.forgotPassword('a@example.com'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
