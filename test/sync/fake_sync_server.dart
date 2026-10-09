import 'dart:convert';

import 'package:http/http.dart' as http;

/// An in-memory stand-in for the sync part of `backend/` with the same
/// rules (`sync.service.ts`, `merge.ts`): versions, a global change
/// sequence, idempotent mutations, field merge for children and settings,
/// version checks for journeys and a grow-only usage counter. The backend's
/// own end-to-end tests check the real server against the same contract.
class FakeSyncServer {
  int _seq = 0;
  final children = <String, Map<String, dynamic>>{};
  final settings = <String, Map<String, dynamic>>{};
  final attempts = <String, Map<String, dynamic>>{};
  final journeys = <String, Map<String, dynamic>>{};
  final usage = <String, Map<String, dynamic>>{};
  final _processed = <String, Map<String, dynamic>>{};

  /// Every request as `METHOD path`.
  final requests = <String>[];

  bool offline = false;

  /// The next push is applied but its answer never arrives.
  bool loseNextAnswer = false;
  bool emailVerified = true;

  static const _identity = {'displayName', 'gender'};
  static const _childKeys = ['displayName', 'gender', 'avatar', 'palette'];

  Future<http.Response> handle(http.Request r) async {
    requests.add('${r.method} ${r.url.path}');
    if (offline) throw http.ClientException('offline');
    switch (r.url.path) {
      case '/api/v1/auth/login' || '/api/v1/auth/refresh':
        return _json({
          'accessToken': 'A.${requests.length}',
          'tokenType': 'Bearer',
          'expiresIn': 900,
          'refreshToken': 'R' * 43,
          'user': {
            'id': '0192f0a0-0000-7000-8000-000000000001',
            'email': 'parent@example.com',
            'emailVerified': emailVerified,
            'signInMethods': ['password'],
            'createdAt': '2026-10-09T10:00:00.000Z',
          },
        });
      case '/api/v1/sync/push':
        if (!emailVerified) return _problem(403, 'email_not_verified');
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final device = body['deviceId'] as String;
        final results = [
          for (final m in body['mutations'] as List)
            _apply(device, Map<String, dynamic>.from(m as Map)),
        ];
        if (loseNextAnswer) {
          loseNextAnswer = false;
          throw http.ClientException('connection reset');
        }
        return _json({'results': results});
      case '/api/v1/sync/pull':
        if (!emailVerified) return _problem(403, 'email_not_verified');
        final since = int.parse(r.url.queryParameters['since'] ?? '0');
        final limit = int.parse(r.url.queryParameters['limit'] ?? '200');
        return _json(_pull(since, limit));
    }
    return _problem(404, 'not_found');
  }

  static http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );

  static http.Response _problem(int status, String code) => http.Response(
    jsonEncode({'type': 'about:blank', 'status': status, 'code': code}),
    status,
    headers: {'content-type': 'application/problem+json'},
  );

  int _next() => ++_seq;

  Map<String, dynamic> _apply(String device, Map<String, dynamic> m) {
    final id = m['mutationId'] as String;
    final done = _processed[id];
    if (done != null) return done;
    final result = {'mutationId': id, ..._dispatch(device, m)};
    _processed[id] = result;
    return result;
  }

  Map<String, dynamic> _rejected(String code) => {
    'status': 'rejected',
    'error': {'code': code},
  };

  Map<String, dynamic>? _liveError(String childId) {
    final child = children[childId];
    if (child == null) return _rejected('child_not_found');
    if (child['deleted'] == true) return _rejected('child_deleted');
    return null;
  }

  Map<String, dynamic> _fields(Map<String, dynamic> child) => {
    for (final k in _childKeys) k: child[k],
  };

  Map<String, dynamic> _dispatch(String device, Map<String, dynamic> m) {
    final payload = Map<String, dynamic>.from(m['payload'] as Map? ?? {});
    switch ((m['entity'], m['op'])) {
      case ('child', 'create'):
        final id = m['id'] as String;
        final fields = {for (final k in _childKeys) k: payload[k]};
        final own = children[id];
        if (own != null) {
          if (own['deleted'] == true) return _rejected('child_deleted');
          final differ = [
            for (final k in _childKeys)
              if (own[k] != fields[k]) k,
          ];
          return differ.isEmpty
              ? {'status': 'duplicate', 'version': own['version']}
              : {
                  'status': 'conflict',
                  'version': own['version'],
                  'conflictFields': differ,
                  'server': {
                    'kind': 'child',
                    ..._fields(own),
                    'version': own['version'],
                  },
                };
        }
        children[id] = {...fields, 'version': 1, 'changeSeq': _next()};
        settings[id] = {
          ...Map<String, dynamic>.from(payload['settings'] as Map),
          'version': 1,
          'changeSeq': _next(),
        };
        return {'status': 'applied', 'version': 1};
      case ('child', 'patch'):
        final id = m['id'] as String;
        final error = _liveError(id);
        if (error != null) return error;
        final child = children[id]!;
        final merge = _merge(
          child,
          payload,
          m['base'] as Map?,
          m['baseVersion'] as int,
          _identity,
        );
        if (merge.applied) {
          child['version'] = (child['version'] as int) + 1;
          child['changeSeq'] = _next();
        }
        return {
          'status': merge.conflicts.isEmpty ? 'applied' : 'conflict',
          'version': child['version'],
          if (merge.conflicts.isNotEmpty) ...{
            'conflictFields': merge.conflicts,
            'server': {
              'kind': 'child',
              ..._fields(child),
              'version': child['version'],
            },
          },
        };
      case ('child', 'delete'):
        final id = m['id'] as String;
        final child = children[id];
        if (child == null) return _rejected('child_not_found');
        if (child['deleted'] != true) {
          child['deleted'] = true;
          child['version'] = (child['version'] as int) + 1;
          child['changeSeq'] = _next();
        }
        return {'status': 'applied', 'version': child['version']};
      case ('settings', 'patch'):
        final childId = m['childId'] as String;
        final error = _liveError(childId);
        if (error != null) return error;
        final row = settings[childId]!;
        final merge = _merge(
          row,
          payload,
          m['base'] as Map?,
          m['baseVersion'] as int,
          const {},
        );
        if (merge.applied) {
          row['version'] = (row['version'] as int) + 1;
          row['changeSeq'] = _next();
        }
        return {'status': 'applied', 'version': row['version']};
      case ('attempt', 'create'):
        final childId = m['childId'] as String;
        final error = _liveError(childId);
        if (error != null) return error;
        final id = m['id'] as String;
        final existing = attempts[id];
        if (existing != null) {
          return jsonEncode(existing['data']) == jsonEncode(payload) ||
                  existing['deleted'] == true
              ? {'status': 'duplicate'}
              : _rejected('immutable');
        }
        attempts[id] = {
          'childId': childId,
          'data': payload,
          'changeSeq': _next(),
        };
        return {'status': 'applied'};
      case ('attempt', 'delete'):
        final childId = m['childId'] as String;
        final row = attempts[m['id']];
        if (children[childId]?['deleted'] == true) return {'status': 'applied'};
        if (row != null && row['deleted'] != true) {
          row['deleted'] = true;
          row['changeSeq'] = _next();
        }
        return {'status': 'applied'};
      case ('journey', 'put'):
        final childId = m['childId'] as String;
        final error = _liveError(childId);
        if (error != null) return error;
        final key = '$childId|${m['curriculum']}|${m['key']}';
        final row = journeys[key];
        if (row == null) {
          journeys[key] = {
            'childId': childId,
            'curriculum': m['curriculum'],
            'key': m['key'],
            'state': payload['state'],
            'version': 1,
            'changeSeq': _next(),
          };
          return {'status': 'applied', 'version': 1};
        }
        if (row['version'] != m['baseVersion']) {
          return {
            'status': 'conflict',
            'version': row['version'],
            'server': row['deleted'] == true
                ? null
                : {
                    'kind': 'journey',
                    'state': row['state'],
                    'contentVersion': null,
                    'version': row['version'],
                  },
          };
        }
        row
          ..['state'] = payload['state']
          ..['deleted'] = false
          ..['version'] = (row['version'] as int) + 1
          ..['changeSeq'] = _next();
        return {'status': 'applied', 'version': row['version']};
      case ('journey', 'delete'):
        final childId = m['childId'] as String;
        if (children[childId]?['deleted'] == true) return {'status': 'applied'};
        final error = _liveError(childId);
        if (error != null) return error;
        final row = journeys['$childId|${m['curriculum']}|${m['key']}'];
        if (row != null && row['deleted'] != true) {
          row
            ..['deleted'] = true
            ..['state'] = null
            ..['version'] = (row['version'] as int) + 1
            ..['changeSeq'] = _next();
        }
        return {'status': 'applied', 'version': ?row?['version']};
      case ('usage', 'put'):
        final childId = m['childId'] as String;
        final error = _liveError(childId);
        if (error != null) return error;
        final key = '$childId|$device|${m['day']}';
        final seconds = payload['seconds'] as int;
        final row = usage[key];
        if (row == null || (row['seconds'] as int) < seconds) {
          usage[key] = {
            'childId': childId,
            'deviceId': device,
            'day': m['day'],
            'seconds': seconds,
            'changeSeq': _next(),
          };
        }
        return {'status': 'applied'};
    }
    return _rejected('validation_failed');
  }

  ({bool applied, List<String> conflicts}) _merge(
    Map<String, dynamic> current,
    Map<String, dynamic> patch,
    Map<dynamic, dynamic>? base,
    int baseVersion,
    Set<String> identity,
  ) {
    final upToDate = baseVersion == current['version'];
    var applied = false;
    final conflicts = <String>[];
    for (final e in patch.entries) {
      if (current[e.key] == e.value) continue;
      final unchanged =
          upToDate ||
          (base != null &&
              base.containsKey(e.key) &&
              base[e.key] == current[e.key]);
      if (unchanged || !identity.contains(e.key)) {
        current[e.key] = e.value;
        applied = true;
      } else {
        conflicts.add(e.key);
      }
    }
    return (applied: applied, conflicts: conflicts);
  }

  Map<String, dynamic> _pull(int since, int limit) {
    final changes =
        <Map<String, dynamic>>[
          for (final e in children.entries)
            {
              'entity': 'child',
              'op': e.value['deleted'] == true ? 'delete' : 'upsert',
              'id': e.key,
              'changeSeq': e.value['changeSeq'],
              'version': e.value['version'],
              if (e.value['deleted'] != true) 'data': _fields(e.value),
            },
          for (final e in settings.entries)
            {
              'entity': 'settings',
              'op': 'upsert',
              'childId': e.key,
              'changeSeq': e.value['changeSeq'],
              'version': e.value['version'],
              'data': {
                for (final k in e.value.keys)
                  if (k != 'version' && k != 'changeSeq') k: e.value[k],
              },
            },
          for (final e in attempts.entries)
            {
              'entity': 'attempt',
              'op': e.value['deleted'] == true ? 'delete' : 'upsert',
              'id': e.key,
              'childId': e.value['childId'],
              'changeSeq': e.value['changeSeq'],
              if (e.value['deleted'] != true) 'data': e.value['data'],
            },
          for (final j in journeys.values)
            {
              'entity': 'journey',
              'op': j['deleted'] == true ? 'delete' : 'upsert',
              'childId': j['childId'],
              'curriculum': j['curriculum'],
              'key': j['key'],
              'changeSeq': j['changeSeq'],
              'version': j['version'],
              if (j['deleted'] != true)
                'data': {'state': j['state'], 'contentVersion': null},
            },
          for (final u in usage.values)
            {
              'entity': 'usage',
              'op': 'upsert',
              'childId': u['childId'],
              'deviceId': u['deviceId'],
              'day': u['day'],
              'seconds': u['seconds'],
              'changeSeq': u['changeSeq'],
            },
        ].where((c) => (c['changeSeq'] as int) > since).toList()..sort(
          (a, b) => (a['changeSeq'] as int).compareTo(b['changeSeq'] as int),
        );
    final page = changes.take(limit).toList();
    return {
      'changes': page,
      'cursor': page.isEmpty ? since : page.last['changeSeq'],
      'hasMore': changes.length > limit,
    };
  }
}
