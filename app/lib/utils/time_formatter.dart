import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

String formatTimestamp(BuildContext context, DateTime itemDate) {
  final l10n = AppLocalizations.of(context)!;
  final nowLocal = DateTime.now();
  final itemLocal = itemDate.toLocal();

  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final itemDay = DateTime(itemLocal.year, itemLocal.month, itemLocal.day);
  final dayDifference = today.difference(itemDay).inDays;

  if (dayDifference == 0) {
    final elapsed = nowLocal.difference(itemLocal);
    if (elapsed.inMinutes < 1) {
      return l10n.justNow;
    } else if (elapsed.inMinutes < 60) {
      return l10n.minutesAgo(elapsed.inMinutes);
    } else {
      return l10n.hoursAgo(elapsed.inHours);
    }
  } else if (dayDifference == 1) {
    return l10n.yesterday;
  } else {
    return '${itemLocal.day}/${itemLocal.month}/${itemLocal.year}';
  }
}
