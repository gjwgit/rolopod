/// ContactParser — imports contacts from BBDB and vCard formats.
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

// ── BBDB parser ───────────────────────────────────────────────────────────────

/// Parse an Emacs BBDB file into a list of [Contact] records.
///
/// BBDB format is a series of Lisp-like records, one per line:
/// ["First" "Last" ("nick") ("org") ("phone") ("addr") ("mail") ... "notes"]
List<Contact> parseBbdb(String content, {required String bookName}) {
  final contacts = <Contact>[];

  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(';')) continue;

    try {
      final c = _parseBbdbRecord(trimmed, bookName: bookName);
      if (c != null) contacts.add(c);
    } catch (e) {
      debugPrint('[BBDB] Parse error on line: $e');
    }
  }

  debugPrint('[BBDB] Parsed ${contacts.length} contacts');
  return contacts;
}

Contact? _parseBbdbRecord(String line, {required String bookName}) {
  // BBDB records are wrapped in [ ... ]
  if (!line.startsWith('[')) return null;

  // Extract quoted string fields using a simple tokeniser.
  final tokens = _bbdbTokenise(line);
  if (tokens.length < 7) return null;

  final firstName = tokens[0].isEmpty ? null : tokens[0];
  final lastName = tokens[1].isEmpty ? null : tokens[1];

  // tokens[2] = ("nick1" "nick2" ...) — take first
  final nicknames = _extractList(tokens[2]);
  final nickname = nicknames.isEmpty ? null : nicknames.first;

  // tokens[3] = ("org")
  final orgs = _extractList(tokens[3]);
  final organisation = orgs.isEmpty ? null : orgs.first;

  // tokens[4] = phones (list of ["label" "number"])
  final phones = _parseBbdbPhones(tokens[4]);

  // tokens[5] = addresses (complex — skip for now, store as note)
  // tokens[6] = emails
  final emails = _extractList(tokens[6])
      .map((e) => ContactField(label: 'email', value: e))
      .toList();

  // notes may be in tokens[8] or later
  final notes = tokens.length > 8 ? _unquote(tokens[8]) : null;

  return Contact(
    bookName: bookName,
    firstName: firstName,
    lastName: lastName,
    nickname: nickname,
    organisation: organisation,
    emails: emails,
    phones: phones,
    notes: notes,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Very simple BBDB tokeniser — extracts top-level fields.
List<String> _bbdbTokenise(String line) {
  // Strip outer brackets
  final inner = line.replaceFirst(RegExp(r'^\['), '').replaceFirst(RegExp(r'\]$'), '');
  final tokens = <String>[];
  var i = 0;

  while (i < inner.length) {
    if (inner[i] == '"') {
      // Quoted string
      final end = _findClosingQuote(inner, i + 1);
      tokens.add(inner.substring(i + 1, end));
      i = end + 1;
    } else if (inner[i] == '(') {
      // Parenthesised list
      final end = _findClosingParen(inner, i + 1);
      tokens.add(inner.substring(i, end + 1));
      i = end + 1;
    } else if (inner[i] == 'n' && inner.substring(i, i + 3) == 'nil') {
      tokens.add('');
      i += 3;
    } else {
      i++;
    }
  }

  return tokens;
}

int _findClosingQuote(String s, int start) {
  for (var i = start; i < s.length; i++) {
    if (s[i] == '"' && (i == 0 || s[i - 1] != '\\')) return i;
  }
  return s.length;
}

int _findClosingParen(String s, int start) {
  var depth = 1;
  for (var i = start; i < s.length; i++) {
    if (s[i] == '(') depth++;
    if (s[i] == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return s.length;
}

List<String> _extractList(String token) {
  if (!token.startsWith('(')) return [];
  final inner = token.substring(1, token.length - 1);
  final results = <String>[];
  final re = RegExp(r'"((?:[^"\\]|\\.)*)"');
  for (final m in re.allMatches(inner)) {
    results.add(m.group(1) ?? '');
  }
  return results;
}

List<ContactField> _parseBbdbPhones(String token) {
  if (!token.startsWith('(')) return [];
  // Each phone is ["label" "number"] or ["label" digits...]
  final phones = <ContactField>[];
  final re = RegExp(r'\["([^"]*)"[^"]*"([^"]*)"\]');
  for (final m in re.allMatches(token)) {
    phones.add(ContactField(label: m.group(1) ?? 'phone', value: m.group(2) ?? ''));
  }
  return phones;
}

String _unquote(String s) => s.replaceAll('"', '').trim();

// ── vCard parser ──────────────────────────────────────────────────────────────

/// Parse a vCard file (v3.0 or v4.0) into a list of [Contact] records.
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

Contact? _parseVcardBlock(String block, {required String bookName}) {
  // Unfold continuation lines
  final unfolded = block.replaceAll(RegExp(r'\r?\n[ \t]'), '');
  final lines = unfolded.split(RegExp(r'\r?\n'));

  String? firstName, lastName, displayName, nickname, organisation, jobTitle, notes;
  final emails = <ContactField>[];
  final phones = <ContactField>[];
  final addresses = <ContactAddress>[];
  final urls = <ContactField>[];

  for (final line in lines) {
    if (line.isEmpty) continue;
    final colon = line.indexOf(':');
    if (colon < 0) continue;

    final key = line.substring(0, colon).toUpperCase();
    final value = line.substring(colon + 1).trim();

    if (key == 'FN') {
      displayName = value;
    } else if (key.startsWith('N')) {
      // N:Last;First;Middle;Prefix;Suffix
      final parts = value.split(';');
      lastName = parts.isNotEmpty ? _vcardDecode(parts[0]) : null;
      firstName = parts.length > 1 ? _vcardDecode(parts[1]) : null;
    } else if (key.startsWith('EMAIL')) {
      final label = _vcardParam(key, 'TYPE') ?? 'email';
      if (value.isNotEmpty) emails.add(ContactField(label: label.toLowerCase(), value: value));
    } else if (key.startsWith('TEL')) {
      final label = _vcardParam(key, 'TYPE') ?? 'phone';
      if (value.isNotEmpty) phones.add(ContactField(label: label.toLowerCase(), value: value));
    } else if (key.startsWith('ADR')) {
      final label = _vcardParam(key, 'TYPE') ?? 'address';
      final parts = value.split(';');
      // ADR:pobox;ext;street;city;state;postcode;country
      addresses.add(ContactAddress(
        label: label.toLowerCase(),
        street: parts.length > 2 ? _vcardDecode(parts[2]) : null,
        city: parts.length > 3 ? _vcardDecode(parts[3]) : null,
        state: parts.length > 4 ? _vcardDecode(parts[4]) : null,
        postcode: parts.length > 5 ? _vcardDecode(parts[5]) : null,
        country: parts.length > 6 ? _vcardDecode(parts[6]) : null,
      ));
    } else if (key.startsWith('URL')) {
      if (value.isNotEmpty) urls.add(ContactField(label: 'url', value: value));
    } else if (key == 'ORG') {
      organisation = value.split(';').first;
    } else if (key == 'TITLE') {
      jobTitle = value;
    } else if (key == 'NICKNAME') {
      nickname = value;
    } else if (key == 'NOTE') {
      notes = _vcardDecode(value);
    }
  }

  if (displayName == null && firstName == null && lastName == null &&
      emails.isEmpty && phones.isEmpty) {
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
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Extract a TYPE parameter from a vCard key like EMAIL;TYPE=WORK.
String? _vcardParam(String key, String param) {
  final re = RegExp('$param=([^;:]+)', caseSensitive: false);
  final m = re.firstMatch(key);
  return m?.group(1);
}

/// Decode common vCard escape sequences.
String _vcardDecode(String s) =>
    s.replaceAll('\\n', '\n').replaceAll('\\,', ',').replaceAll('\\;', ';').trim();
