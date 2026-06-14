/// VcardParser — import contacts from vCard v3.0 and v4.0 files.
///
// Time-stamp: <2026-03-22 Graham Williams>
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

import 'package:flutter/foundation.dart';

import 'package:rolopod/models/contact.dart';

// ── Date parser ───────────────────────────────────────────────────────────────

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return DateTime.parse(s.replaceFirst(RegExp(r' \+\d{4}$'), 'Z'));
  } catch (_) {
    return null;
  }
}

List<Contact> parseVcard(String content, {required String bookName}) {
  final contacts = <Contact>[];
  final cards = content.split(RegExp(r'END:VCARD', caseSensitive: false));

  for (final card in cards) {
    if (!card.contains(RegExp(r'BEGIN:VCARD', caseSensitive: false))) continue;
    try {
      final c = _parseVcardBlock(card, bookName: bookName);
      if (c != null) contacts.add(c);
    } catch (e) {
      debugPrint('[vCard] Parse error: $e');
    }
  }

  debugPrint('[vCard] Parsed ${contacts.length} contacts');
  return contacts;
}

// ── Export ──────────────────────────────────────────────────────────────────

/// Escape a value for inclusion in a vCard field.
String _vEncode(String s) => s
    .replaceAll('\\', r'\\')
    .replaceAll('\n', r'\n')
    .replaceAll(',', r'\,')
    .replaceAll(';', r'\;');

/// Serialise [contacts] to a vCard 3.0 document.
String toVcard(List<Contact> contacts) {
  final buf = StringBuffer();
  for (final c in contacts) {
    buf.writeln('BEGIN:VCARD');
    buf.writeln('VERSION:3.0');
    buf.writeln(
      'N:${_vEncode(c.lastName ?? '')};${_vEncode(c.firstName ?? '')};;;',
    );
    buf.writeln('FN:${_vEncode(c.displayName ?? c.name)}');
    if (c.nickname != null && c.nickname!.isNotEmpty) {
      buf.writeln('NICKNAME:${_vEncode(c.nickname!)}');
    }
    if (c.organisation != null && c.organisation!.isNotEmpty) {
      buf.writeln('ORG:${_vEncode(c.organisation!)}');
    }
    if (c.jobTitle != null && c.jobTitle!.isNotEmpty) {
      buf.writeln('TITLE:${_vEncode(c.jobTitle!)}');
    }
    for (final e in c.emails) {
      buf.writeln('EMAIL;TYPE=${e.label}:${e.value}');
    }
    for (final p in c.phones) {
      buf.writeln('TEL;TYPE=${p.label}:${p.value}');
    }
    for (final a in c.addresses) {
      buf.writeln(
        'ADR;TYPE=${a.label}:;;${_vEncode(a.street ?? '')};'
        '${_vEncode(a.city ?? '')};${_vEncode(a.state ?? '')};'
        '${_vEncode(a.postcode ?? '')};${_vEncode(a.country ?? '')}',
      );
    }
    for (final u in c.urls) {
      buf.writeln('URL:${u.value}');
    }
    if (c.birthday != null) {
      buf.writeln(
        'BDAY:${c.birthday!.toIso8601String().substring(0, 10)}',
      );
    }
    if (c.notes != null && c.notes!.isNotEmpty) {
      buf.writeln('NOTE:${_vEncode(c.notes!)}');
    }
    if (c.tags.isNotEmpty) {
      buf.writeln('CATEGORIES:${c.tags.join(',')}');
    }
    buf.writeln('END:VCARD');
  }
  return buf.toString();
}

Contact? _parseVcardBlock(String block, {required String bookName}) {
  final unfolded = block.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  final lines = unfolded.split(RegExp(r'\r?\n'));

  String? firstName,
      lastName,
      displayName,
      nickname,
      organisation,
      jobTitle,
      notes;
  DateTime? birthday;
  final emails = <ContactField>[];
  final phones = <ContactField>[];
  final addresses = <ContactAddress>[];
  final urls = <ContactField>[];
  final tags = <String>[];

  for (final line in lines) {
    if (line.isEmpty) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;
    final key = line.substring(0, colon).toUpperCase();
    final value = line.substring(colon + 1).trim();

    if (key == 'FN') {
      displayName = value;
    } else if (key.startsWith('N;') || key == 'N') {
      final parts = value.split(';');
      lastName = parts.isNotEmpty ? _vDecode(parts[0]) : null;
      firstName = parts.length > 1 ? _vDecode(parts[1]) : null;
    } else if (key.startsWith('EMAIL')) {
      final label = _vParam(key, 'TYPE') ?? 'email';
      if (value.isNotEmpty) {
        emails.add(ContactField(label: label.toLowerCase(), value: value));
      }
    } else if (key.startsWith('TEL')) {
      final label = _vParam(key, 'TYPE') ?? 'phone';
      if (value.isNotEmpty) {
        phones.add(ContactField(label: label.toLowerCase(), value: value));
      }
    } else if (key.startsWith('ADR')) {
      final label = _vParam(key, 'TYPE') ?? 'address';
      final parts = value.split(';');
      addresses.add(
        ContactAddress(
          label: label.toLowerCase(),
          street: parts.length > 2 ? _vDecode(parts[2]) : null,
          city: parts.length > 3 ? _vDecode(parts[3]) : null,
          state: parts.length > 4 ? _vDecode(parts[4]) : null,
          postcode: parts.length > 5 ? _vDecode(parts[5]) : null,
          country: parts.length > 6 ? _vDecode(parts[6]) : null,
        ),
      );
    } else if (key.startsWith('URL')) {
      if (value.isNotEmpty) {
        urls.add(ContactField(label: 'url', value: value));
      }
    } else if (key == 'ORG') {
      organisation = value.split(';').first;
    } else if (key == 'TITLE') {
      jobTitle = value;
    } else if (key == 'NICKNAME') {
      nickname = value;
    } else if (key == 'NOTE') {
      notes = _vDecode(value);
    } else if (key == 'BDAY') {
      birthday = _parseDate(value);
    } else if (key == 'CATEGORIES') {
      tags.addAll(
        value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty),
      );
    }
  }

  if (displayName == null &&
      firstName == null &&
      lastName == null &&
      emails.isEmpty &&
      phones.isEmpty) {
    return null;
  }

  return Contact(
    bookName: bookName,
    firstName: firstName?.isEmpty == true ? null : firstName,
    lastName: lastName?.isEmpty == true ? null : lastName,
    displayName: displayName?.isEmpty == true ? null : displayName,
    nickname: nickname,
    organisation: organisation,
    jobTitle: jobTitle,
    emails: emails,
    phones: phones,
    addresses: addresses,
    urls: urls,
    notes: notes,
    tags: tags,
    birthday: birthday,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

String? _vParam(String key, String param) {
  final re = RegExp('$param=([^;:]+)', caseSensitive: false);
  return re.firstMatch(key)?.group(1);
}

String _vDecode(String s) => s
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .trim();
