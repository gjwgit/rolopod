/// RoloPod - a month calendar that marks contacts' birthdays.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3-0.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://www.gnu.org/licenses/gpl-3.0.html>.
///
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/contact_detail.dart';
import 'package:rolopod/screens/birthday_calendar_grid.dart';
import 'package:rolopod/services/app_provider.dart';

// Displays a month-at-a-glance calendar. Days that are the birthday of one or
// more visible contacts are marked with a dot; tapping a day lists those
// contacts. Birthdays match on month and day only, so they recur every year
// regardless of the stored birth year.

class BirthdayCalendarScreen extends StatefulWidget {
  const BirthdayCalendarScreen({super.key});

  @override
  State<BirthdayCalendarScreen> createState() => _BirthdayCalendarScreenState();
}

class _BirthdayCalendarScreenState extends State<BirthdayCalendarScreen> {
  // First day of the month currently shown.
  late DateTime _month;

  // The day the user has selected (null until they tap one).
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selectedDay = null;
    });
  }

  // Toggle the day filter: tapping a day selects it (list shows only that
  // day); tapping the same day again clears it (list shows the whole month).

  void _onSelectDay(DateTime day) {
    setState(() {
      final same = _selectedDay != null &&
          _selectedDay!.year == day.year &&
          _selectedDay!.month == day.month &&
          _selectedDay!.day == day.day;
      _selectedDay = same ? null : day;
    });
  }

  // Build a map from day-of-month to the contacts whose birthday falls on that
  // day within the displayed month.

  Map<int, List<Contact>> _birthdaysForMonth(List<Contact> contacts) {
    final map = <int, List<Contact>>{};
    for (final c in contacts) {
      final b = c.birthday;
      if (b == null) continue;
      if (b.month != _month.month) continue;
      map.putIfAbsent(b.day, () => []).add(c);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  }

  void _openContact(Contact contact) {
    showDialog<void>(
      context: context,
      builder: (_) => ContactDetail(contact: contact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final byDay = _birthdaysForMonth(provider.visibleContactsUnfiltered);

    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Keep the calendar itself compact and centred.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _monthHeader(context),
                    const SizedBox(height: 8),
                    _weekdayLabels(context),
                    const SizedBox(height: 4),
                    CalendarGrid(
                      month: _month,
                      selectedDay: _selectedDay,
                      birthdaysByDay: byDay,
                      onSelectDay: _onSelectDay,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // The full list of this month's birthdays, widened a little more.
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _monthList(context, byDay),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The birthday list below the calendar. When a day is selected (tapped),
  // only that day's birthdays are shown; otherwise the whole month is listed.

  Widget _monthList(BuildContext context, Map<int, List<Contact>> byDay) {
    final cs = Theme.of(context).colorScheme;
    final sel = _selectedDay;
    final filtering = sel != null && sel.month == _month.month;

    // Choose which days to show.
    final days = (filtering ? [sel.day] : byDay.keys.toList())..sort();
    final total = filtering
        ? (byDay[sel.day]?.length ?? 0)
        : byDay.values.fold<int>(0, (s, l) => s + l.length);

    final heading = filtering
        ? 'Birthdays on ${sel.day} ${_monthName(_month.month)}'
        : 'Birthdays in ${_monthName(_month.month)}';

    if (total == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filtering)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Tap the day again to show the whole month.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              filtering
                  ? 'No birthdays on ${sel.day} ${_monthName(_month.month)}.'
                  : 'No birthdays in ${_monthName(_month.month)}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (filtering)
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Show month'),
                onPressed: () => setState(() => _selectedDay = null),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final day in days)
          for (final c in (byDay[day] ?? const []))
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.cake, color: cs.onPrimaryContainer),
                ),
                title: Text(c.name),
                subtitle: Text(
                  '$day ${_monthName(_month.month)}  ·  '
                  '${_ageText(c.birthday!)}',
                ),
                onTap: () => _openContact(c),
              ),
            ),
      ],
    );
  }

  Widget _monthHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: () => _changeMonth(-1),
        ),
        Expanded(
          child: Text(
            '${_monthName(_month.month)} ${_month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: () => _changeMonth(1),
        ),
        TextButton(onPressed: _goToday, child: const Text('Today')),
      ],
    );
  }

  Widget _weekdayLabels(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(child: Text(l, style: style)),
            ),
          )
          .toList(),
    );
  }

  String _ageText(DateTime birthday) {
    final hasYear = birthday.year > 1900;
    if (!hasYear) return 'Birthday';
    // The age they turn on this birthday is simply the calendar year being
    // viewed minus their birth year.
    final turning = _month.year - birthday.year;
    return 'Turning $turning';
  }

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][m - 1];
}
