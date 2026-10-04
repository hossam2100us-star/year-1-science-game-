import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Strings for the parent area, which follows the parent's language setting
/// (AppSettings.arabic) rather than the device locale (AUD-011).
AppLocalizations parentStrings(bool arabic) =>
    lookupAppLocalizations(Locale(arabic ? 'ar' : 'en'));
