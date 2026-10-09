/// An answer from the server that is not a success (RFC 9457 problem).
class ApiProblem implements Exception {
  ApiProblem(this.status, this.code, {this.detail, this.retryAfter, this.body});

  final int status;

  /// Stable machine-readable code, e.g. `invalid_credentials`.
  final String code;
  final String? detail;
  final Duration? retryAfter;

  /// The whole problem document (for example a version conflict's `server`).
  final Map<String, dynamic>? body;

  bool get isAuth => status == 401;

  @override
  String toString() => 'ApiProblem($status, $code)';
}

/// The server could not be reached (offline, DNS, timeout, TLS). Play never
/// waits for this; sync simply tries again later.
class NetworkFailure implements Exception {
  NetworkFailure(this.reason);
  final String reason;

  @override
  String toString() => 'NetworkFailure($reason)';
}

/// The parent is not signed in (or the session ended); sign-in is needed.
class SignedOut implements Exception {
  @override
  String toString() => 'SignedOut';
}
