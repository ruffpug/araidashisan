import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// AppLocalizationsを取得する。
AppLocalizations requireAppLocalizations(BuildContext context) {
  return AppLocalizations.of(context)!;
}
