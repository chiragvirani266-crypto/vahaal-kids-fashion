import 'package:flutter/material.dart';

enum BillDateFilterOption {
  all('All Time'),
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom Range');

  final String label;
  const BillDateFilterOption(this.label);
}

class BillFilterHelper {
  static DateTimeRange? resolveDateRange(
    BillDateFilterOption option, {
    DateTimeRange? customRange,
  }) {
    final now = DateTime.now();
    switch (option) {
      case BillDateFilterOption.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BillDateFilterOption.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BillDateFilterOption.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BillDateFilterOption.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BillDateFilterOption.custom:
        if (customRange != null) {
          final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
          return DateTimeRange(start: start, end: end);
        }
        return null;

      case BillDateFilterOption.all:
        return null;
    }
  }
}
