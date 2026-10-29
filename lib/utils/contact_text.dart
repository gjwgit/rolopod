/// ContactText — a plain text rendering of a contact for the clipboard.
///
// Time-stamp: <Thursday 2026-10-29 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

import 'package:rolopod/models/contact.dart';

/// The details of contact [c] as plain text, one item per line, suitable for
/// pasting into an email, message or another app. Empty fields are omitted.

String contactAsText(Contact c) {
  String labelled(String label, String value) =>
      label.isEmpty ? value : '$value ($label)';

  final b = c.birthday;

  return [
    c.name,
    [c.jobTitle, c.organisation].whereType<String>().join(', '),
    for (final e in c.emails) labelled(e.label, e.value),
    for (final p in c.phones) labelled(p.label, p.value),
    for (final a in c.addresses) labelled(a.label, a.summary),
    for (final u in c.urls) labelled(u.label, u.value),
    if (b != null) 'Birthday: ${b.day}/${b.month}/${b.year}',
    if (c.notes != null && c.notes!.trim().isNotEmpty) '\n${c.notes!.trim()}',
  ].where((line) => line.trim().isNotEmpty).join('\n');
}
