import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_adventure/core/models.dart';
import 'package:science_adventure/core/storage.dart';
import 'package:science_adventure/parent/children_section.dart';
import 'package:science_adventure/l10n/parent_strings.dart';

import 'setup_screen_test.dart' as helpers;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localisation resources (AUD-011)', () {
    Map<String, dynamic> arb(String locale) =>
        jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>;

    test('every English message has an Arabic translation', () {
      final en = arb('en'), ar = arb('ar');
      final keys = en.keys.where((k) => !k.startsWith('@'));
      for (final key in keys) {
        expect(ar[key], isA<String>(), reason: key);
        expect((ar[key] as String).trim(), isNotEmpty, reason: key);
      }
    });

    test('placeholders match in both languages', () {
      final en = arb('en'), ar = arb('ar');
      final placeholder = RegExp(r'\{(\w+)\}');
      for (final key in en.keys.where((k) => !k.startsWith('@'))) {
        Set<String> names(String text) =>
            placeholder.allMatches(text).map((m) => m.group(1)!).toSet();
        expect(names(ar[key] as String), names(en[key] as String), reason: key);
      }
    });

    test('parent strings follow the parent language setting', () {
      expect(parentStrings(false).parentAreaGrownUps, 'Grown-ups');
      expect(parentStrings(true).parentAreaGrownUps, 'ركن الأهل');
      expect(parentStrings(false).parentAreaName('Nour'), 'Name: Nour');
    });
  });

  testWidgets(
    'the delete-child dialog is in English when the parent chose English',
    (t) async {
      helpers.testCatalog = (await t.runAsync(helpers.loadTestCatalog))!;
      final store = MemoryProgressStore(
        const AppData(
          profile: ChildProfile(name: 'Nour'),
          settings: AppSettings(arabic: false),
        ).addChild('second', const ChildProfile(name: 'Adam')),
      );
      await helpers.mount(
        t,
        Scaffold(
          body: SingleChildScrollView(
            child: ChildrenOnDevice(arabic: store.data.settings.arabic),
          ),
        ),
        store,
      );
      await helpers.tapVisible(
        t,
        find.byKey(const ValueKey('delete-child-local-child')),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text("Delete Nour's profile?"), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await helpers.tapVisible(t, find.text('Cancel'));
      expect(store.data.childRecords.length, 2);
    },
  );
}
