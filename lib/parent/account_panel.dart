import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/account/account_controller.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_errors.dart';
import '../data/sync/sync_controller.dart';
import '../data/sync/sync_engine.dart';
import '../data/sync/sync_store.dart';
import '../l10n/parent_strings.dart';
import 'parent_section.dart';

/// The parent account tab of the parent area (ADR-0002): device-only by
/// default; a parent account only after the parent chose it and agreed to
/// what is stored; children are saved in the account one by one.
class AccountPanel extends ConsumerStatefulWidget {
  const AccountPanel({super.key, required this.arabic});
  final bool arabic;
  @override
  ConsumerState<AccountPanel> createState() => _AccountPanelState();
}

enum _Form { signIn, create, forgot }

class _AccountPanelState extends ConsumerState<AccountPanel> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  _Form _form = _Form.signIn;
  bool _busy = false;
  String? _error;
  String? _notice;

  AppLocalizations get l => parentStrings(widget.arabic);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  /// Runs [action], showing what went wrong in words a parent understands.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => switch (error) {
    NetworkFailure() => l.accountErrorOffline,
    ApiProblem(code: 'invalid_credentials') => l.accountErrorCredentials,
    ApiProblem(code: 'password_breached') => l.accountErrorBreached,
    ApiProblem(code: 'registration_closed') => l.accountErrorClosed,
    ApiProblem(status: 429) => l.accountErrorBusy,
    LinkException(problem: LinkProblem.name) => l.accountLinkName,
    _ => l.accountErrorGeneric,
  };

  /// Dates and Material texts follow the parent's language, not the device's.
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Locale(widget.arabic ? 'ar' : 'en'),
    child: Builder(builder: _content),
  );

  Widget _content(BuildContext context) {
    final account = ref.watch(accountProvider);
    if (account.mode == AccountMode.deviceOnly) return _deviceOnly(context);
    final user = account.user;
    if (user == null) return _signInForm(context);
    return _signedIn(context, user);
  }

  // ---- device only -----------------------------------------------------------

  Widget _deviceOnly(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ParentSection(
        title: l.accountDeviceOnlyTitle,
        children: [Text(l.accountDeviceOnlyBody)],
      ),
      ParentSection(
        title: l.accountWhyTitle,
        children: [
          Text(l.accountWhyBody),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('account-start'),
            onPressed: _busy
                ? null
                : () async {
                    if (!await askAccountConsent(
                      context,
                      arabic: widget.arabic,
                    )) {
                      return;
                    }
                    await _run(
                      () => ref.read(accountProvider.notifier).useAccount(),
                    );
                  },
            icon: const Icon(Icons.family_restroom_rounded),
            label: Text(l.accountUseAccount),
          ),
        ],
      ),
    ],
  );

  // ---- signing in ------------------------------------------------------------

  bool _validEmail() {
    final email = _email.text.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!ok) setState(() => _error = l.accountEmailInvalid);
    return ok;
  }

  Future<void> _signIn() async {
    if (!_validEmail()) return;
    await _run(() async {
      await ref
          .read(accountProvider.notifier)
          .signIn(_email.text.trim(), _password.text);
      _password.clear();
    });
  }

  Future<void> _create() async {
    if (!_validEmail()) return;
    if (_password.text.length < 12) {
      setState(() => _error = l.accountPasswordShort);
      return;
    }
    if (_password.text != _repeat.text) {
      setState(() => _error = l.accountPasswordsDiffer);
      return;
    }
    await _run(() async {
      final account = ref.read(accountProvider.notifier);
      final email = _email.text.trim();
      await account.register(email, _password.text);
      try {
        await account.signIn(email, _password.text);
      } on ApiProblem catch (e) {
        // The email already had an account with another password.
        if (e.code != 'invalid_credentials') rethrow;
        if (mounted) {
          setState(() {
            _form = _Form.signIn;
            _notice = l.accountCreatedCheckEmail;
          });
        }
      }
      _password.clear();
      _repeat.clear();
    });
  }

  Future<void> _forgot() async {
    if (!_validEmail()) return;
    await _run(() async {
      await ref
          .read(accountProvider.notifier)
          .forgotPassword(_email.text.trim());
      if (mounted) {
        setState(() {
          _form = _Form.signIn;
          _notice = l.accountForgotSent;
        });
      }
    });
  }

  Widget _signInForm(BuildContext context) {
    final creating = _form == _Form.create;
    final forgetting = _form == _Form.forgot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentSection(
          title: creating ? l.accountCreateTitle : l.accountSignInTitle,
          children: [
            if (ref.watch(syncProvider).failure == SyncFailure.signedOut)
              Text(l.accountSyncSignedOut),
            TextField(
              key: const ValueKey('account-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(labelText: l.accountEmail),
            ),
            if (!forgetting) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('account-password'),
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: [
                  creating ? AutofillHints.newPassword : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: l.accountPassword,
                  helperText: creating ? l.accountPasswordRule : null,
                ),
              ),
            ],
            if (creating) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('account-repeat'),
                controller: _repeat,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.accountPasswordRepeat),
              ),
            ],
            const SizedBox(height: 12),
            if (_error != null) _Message(_error!, error: true),
            if (_notice != null) _Message(_notice!),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  key: const ValueKey('account-submit'),
                  onPressed: _busy
                      ? null
                      : switch (_form) {
                          _Form.signIn => _signIn,
                          _Form.create => _create,
                          _Form.forgot => _forgot,
                        },
                  child: Text(switch (_form) {
                    _Form.signIn => l.accountSignIn,
                    _Form.create => l.accountCreate,
                    _Form.forgot => l.accountForgotSend,
                  }),
                ),
                if (_form != _Form.create)
                  TextButton(
                    key: const ValueKey('account-to-create'),
                    onPressed: () => setState(() {
                      _form = _Form.create;
                      _error = null;
                    }),
                    child: Text(l.accountCreate),
                  ),
                if (_form != _Form.signIn)
                  TextButton(
                    onPressed: () => setState(() {
                      _form = _Form.signIn;
                      _error = null;
                    }),
                    child: Text(l.accountHaveAccount),
                  ),
                if (_form == _Form.signIn)
                  TextButton(
                    onPressed: () => setState(() {
                      _form = _Form.forgot;
                      _error = null;
                    }),
                    child: Text(l.accountForgot),
                  ),
              ],
            ),
          ],
        ),
        ParentSection(
          title: l.accountDeviceOnlyTitle,
          children: [
            Text(l.accountLeaveBody),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('account-leave'),
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => ref.read(syncProvider.notifier).leaveAccount(),
                    ),
              child: Text(l.accountBackToDevice),
            ),
          ],
        ),
      ],
    );
  }

  // ---- signed in -------------------------------------------------------------

  Widget _signedIn(BuildContext context, AccountUser user) {
    final sync = ref.watch(syncProvider);
    final data = ref.watch(appProvider);
    final children = [
      for (final e in data.childRecords.entries)
        if (e.value['profile'] != null)
          (
            id: e.key,
            name: e.key == data.activeChildId
                ? data.profile!.name
                : (e.value['profile'] as Map)['name'] as String? ?? '',
          ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!user.emailVerified)
          ParentSection(
            title: l.accountConfirmTitle,
            children: [
              Text(l.accountConfirmEmail(user.email)),
              const SizedBox(height: 12),
              if (_notice != null) _Message(_notice!),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await ref
                                .read(accountProvider.notifier)
                                .refreshUser();
                            await ref.read(syncProvider.notifier).syncNow();
                          }),
                    child: Text(l.accountConfirmed),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await ref
                                .read(accountProvider.notifier)
                                .resendVerification();
                            if (mounted) {
                              setState(() => _notice = l.accountResent);
                            }
                          }),
                    child: Text(l.accountResend),
                  ),
                ],
              ),
            ],
          ),
        ParentSection(
          title: l.accountChildrenTitle,
          children: [
            Text(l.accountChildrenBody),
            const SizedBox(height: 8),
            for (final child in children)
              ListTile(
                key: ValueKey('account-child-${child.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  sync.linked.contains(child.id)
                      ? Icons.cloud_done_rounded
                      : Icons.phone_android_rounded,
                ),
                title: Text(child.name),
                subtitle: Text(
                  sync.linked.contains(child.id)
                      ? l.accountLinked
                      : l.accountNotLinked,
                ),
                trailing: sync.linked.contains(child.id)
                    ? null
                    : OutlinedButton(
                        key: ValueKey('account-link-${child.id}'),
                        onPressed: _busy
                            ? null
                            : () => _link(context, child.id, child.name),
                        child: Text(l.accountLink),
                      ),
              ),
            if (_error != null) _Message(_error!, error: true),
          ],
        ),
        _syncSection(context, sync),
        ParentSection(
          title: l.accountManageTitle,
          children: [
            Text(l.accountSignedInAs(user.email)),
            const SizedBox(height: 8),
            Text(l.accountSignOutBody),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  key: const ValueKey('account-sign-out'),
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => ref.read(accountProvider.notifier).signOut(),
                        ),
                  child: Text(l.accountSignOut),
                ),
                OutlinedButton(
                  key: const ValueKey('account-leave'),
                  onPressed: _busy ? null : () => _leave(context),
                  child: Text(l.accountLeave),
                ),
                if (user.signInMethods.contains('password'))
                  TextButton(
                    key: const ValueKey('account-delete'),
                    onPressed: _busy ? null : () => _delete(context),
                    child: Text(l.accountDelete),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _syncSection(BuildContext context, SyncState sync) {
    final last = sync.lastSync;
    final when = last == null
        ? l.accountSyncNever
        : l.accountSyncLast(_time(context, last.toLocal()));
    final status = switch (sync.failure) {
      SyncFailure.offline => l.accountSyncOffline,
      SyncFailure.unavailable => l.accountSyncUnavailable,
      SyncFailure.unexpected => l.accountSyncUnexpected,
      SyncFailure.signedOut => l.accountSyncSignedOut,
      SyncFailure.emailNotVerified || null =>
        sync.waiting == 0
            ? l.accountSyncAllSent
            : l.accountSyncWaiting(sync.waiting),
    };
    return ParentSection(
      title: l.accountSyncTitle,
      children: [
        Text(when, key: const ValueKey('sync-last')),
        Text(status, key: const ValueKey('sync-status')),
        if (sync.quarantined > 0) ...[
          const SizedBox(height: 8),
          Text(l.accountSyncRefused(sync.quarantined)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => ref.read(syncProvider.notifier).retryRefused(),
              child: Text(l.accountSyncRetry),
            ),
          ),
        ],
        for (final issue in sync.issues) _issue(issue),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const ValueKey('sync-now'),
            onPressed: sync.running
                ? null
                : () => ref.read(syncProvider.notifier).syncNow(),
            icon: const Icon(Icons.sync_rounded),
            label: Text(sync.running ? l.accountSyncRunning : l.accountSyncNow),
          ),
        ),
      ],
    );
  }

  String _time(BuildContext context, DateTime t) {
    final m = MaterialLocalizations.of(context);
    return '${m.formatMediumDate(t)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(t))}';
  }

  Widget _issue(SyncIssue issue) {
    final sync = ref.read(syncProvider.notifier);
    final child = issue.childName;
    final text = switch (issue.kind) {
      'field' when issue.field == 'displayName' => l.accountIssueName(
        child,
        '${issue.theirs}',
        '${issue.mine}',
      ),
      'field' => l.accountIssueGender(child),
      'childRemoved' => l.accountIssueRemoved(child),
      _ => l.accountIssueUnavailable(child),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text),
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => sync.dismiss(issue),
                child: Text(
                  issue.kind == 'field' ? l.accountIssueKeep : l.accountIssueOk,
                ),
              ),
              if (issue.kind == 'field')
                TextButton(
                  onPressed: () => sync.useMine(issue),
                  child: Text(l.accountIssueUseMine),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    Widget? extra,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => Directionality(
          textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            scrollable: true,
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Text(body), ?extra],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: Text(l.accountCancel),
              ),
              FilledButton(
                key: const ValueKey('account-confirm'),
                onPressed: () => Navigator.of(dialog).pop(true),
                child: Text(action),
              ),
            ],
          ),
        ),
      ) ??
      false;

  Future<void> _link(BuildContext context, String id, String name) async {
    if (!SyncStore.nameSyncable(name)) {
      setState(() => _error = l.accountLinkName);
      return;
    }
    if (!await _confirm(
      context,
      title: l.accountLinkConfirmTitle(name),
      body: l.accountLinkConfirmBody,
      action: l.accountLink,
    )) {
      return;
    }
    await _run(() => ref.read(syncProvider.notifier).link(id));
  }

  Future<void> _leave(BuildContext context) async {
    if (!await _confirm(
      context,
      title: l.accountLeave,
      body: l.accountLeaveBody,
      action: l.accountLeave,
    )) {
      return;
    }
    await _run(() => ref.read(syncProvider.notifier).leaveAccount());
  }

  Future<void> _delete(BuildContext context) async {
    final password = TextEditingController();
    try {
      final confirmed = await _confirm(
        context,
        title: l.accountDelete,
        body: l.accountDeleteBody,
        action: l.accountDelete,
        extra: TextField(
          key: const ValueKey('account-delete-password'),
          controller: password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: l.accountPassword),
        ),
      );
      if (!confirmed || password.text.isEmpty) return;
      await _run(() async {
        final when = await ref
            .read(syncProvider.notifier)
            .deleteAccount(password: password.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l.accountDeleteScheduled(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(when.toLocal()),
                ),
              ),
            ),
          );
        }
      });
    } finally {
      password.dispose();
    }
  }
}

/// What a parent agrees to before using an account; each point must be
/// ticked (nothing is pre-ticked). Shared by the first-run question and the
/// parent area.
Future<bool> askAccountConsent(
  BuildContext context, {
  required bool arabic,
}) async {
  final l = parentStrings(arabic);
  final ticks = [false, false, false];
  final points = [
    l.accountConsentParent,
    l.accountConsentData,
    l.accountConsentDelete,
  ];
  final agreed = await showDialog<bool>(
    context: context,
    builder: (dialog) => Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          scrollable: true,
          title: Text(l.accountConsentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.accountConsentTrial),
              const SizedBox(height: 8),
              for (var i = 0; i < points.length; i++)
                CheckboxListTile(
                  key: ValueKey('consent-$i'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: ticks[i],
                  title: Text(points[i]),
                  onChanged: (v) => setLocal(() => ticks[i] = v ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(l.accountCancel),
            ),
            FilledButton(
              key: const ValueKey('consent-continue'),
              onPressed: ticks.every((t) => t)
                  ? () => Navigator.of(dialog).pop(true)
                  : null,
              child: Text(l.accountContinue),
            ),
          ],
        ),
      ),
    ),
  );
  return agreed ?? false;
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        color: error ? Theme.of(context).colorScheme.error : null,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
