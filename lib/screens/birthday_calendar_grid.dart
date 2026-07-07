/// RoloPod - month grid widget for the birthday calendar.
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

import 'package:rolopod/models/contact.dart';

// The month grid itself: a 7-column layout of day cells, with leading blanks
// so the first of the month lands under the correct weekday (Monday-first).

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.birthdaysByDay,
    required this.onSelectDay,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final Map<int, List<Contact>> birthdaysByDay;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Dart weekday: Mon=1 … Sun=7. Leading blanks before day 1.
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }
            final date = DateTime(month.year, month.month, dayNum);
            final hasBirthday = birthdaysByDay.containsKey(dayNum);
            final isSelected = selectedDay != null &&
                selectedDay!.year == date.year &&
                selectedDay!.month == date.month &&
                selectedDay!.day == date.day;
            final isToday = today.year == date.year &&
                today.month == date.month &&
                today.day == date.day;

            return Expanded(
              child: DayCell(
                day: dayNum,
                hasBirthday: hasBirthday,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => onSelectDay(date),
              ),
            );
          }),
        );
      }),
    );
  }
}

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.hasBirthday,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool hasBirthday;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color? bg;
    Color fg = cs.onSurface;
    if (isSelected) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isToday) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: cs.primary, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(color: fg)),
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasBirthday
                    ? (isSelected ? cs.onPrimary : cs.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
