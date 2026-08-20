import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

String formatTimestamp(BuildContext context, DateTime itemDate) {
  final l10n = AppLocalizations.of(context)!;
  final now = DateTime.now().toUtc();
  final today = DateTime(now.year, now.month, now.day);
  final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);
  final dayDifference = today.difference(itemDay).inDays;

  if (dayDifference == 0) {
    final elapsed = now.difference(itemDate);
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
    return '${itemDate.day}/${itemDate.month}/${itemDate.year}';
  }
}