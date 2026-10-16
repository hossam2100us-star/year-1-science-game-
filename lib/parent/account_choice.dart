import 'package:flutter/material.dart';

import '../core/models.dart';
import '../l10n/parent_strings.dart';
import 'parent_gate.dart';

// The first-run question "this device only or a parent account" became the
// login page (login_page.dart), shown each time the app opens until a
// parent signs in.

/// After a child is created while a parent is signed in: offer to save it
/// in the account (the parent confirms behind the gate). Returns whether
/// the parent agreed.
Future<bool> offerToSaveChild(
  BuildContext context, {
  required bool arabic,
  required String name,
  ChildGender? gender,
}) async {
  final l = parentStrings(arabic);
  final save = await showDialog<bool>(
    context: context,
    builder: (dialog) => Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        scrollable: true,
        title: Text(l.accountLinkConfirmTitle(name)),
        content: Text(l.accountLinkConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('offer-not-now'),
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.accountNotNow),
          ),
          FilledButton(
            key: const ValueKey('offer-save'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.accountLink),
          ),
        ],
      ),
    ),
  );
  if (save != true || !context.mounted) return false;
  return parentGate(context, gender: gender);
}
