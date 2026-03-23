/// BbdbParser — tokeniser and record parser for Emacs BBDB format.
///
// Time-stamp: <Monday 2026-03-23 22:12:06 +1100 Graham Williams>
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

// ══════════════════════════════════════════════════════════════════════════════
// BBDB parser
//
// Real BBDB record structure (positional fields 0-based):
//
//   [givenName familyName nickList orgList phoneList addrList emailList xfields
//    uuid createdAt updatedAt notes]
//
// Example:
//   ["Graham" "Williams" nil nil
//    ("anu" "mnm" "family")
//    (["mobile" "+61 4 1228 ..."])
//    (["home" ("12 Abc St") "Mac" "ACT" "1234" "Australia"])
//    ("g@tog.com" "g@acm.org")
//    ((url . "http://...") (birthday . "1980-11-23"))
//    "uuid-string"
//    "2020-12-26 ..." "2021-01-17 ..." nil]
// ══════════════════════════════════════════════════════════════════════════════

List<Contact> parseBbdb(String content, {required String bookName}) {
  final contacts = <Contact>[];
  // Records are one per line, wrapped in [ ... ]
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith(';')) continue;
    try {
      final c = _parseBbdbRecord(trimmed, bookName: bookName);
      if (c != null) contacts.add(c);
    } catch (e, st) {
      debugPrint('[BBDB] Skipping record: $e\n$st');
    }
  }
  debugPrint('[BBDB] Parsed ${contacts.length} contacts');
  return contacts;
}

Contact? _parseBbdbRecord(String line, {required String bookName}) {
  if (!line.startsWith('[')) return null;

  final tokens = _tokenise(line);
  if (tokens.isEmpty) return null;
  final root = tokens.first;
  if (root is! _ListToken) return null;

  final items = root.items;
  if (items.length < 8) return null;

  // ── Confirmed positional layout (from real BBDB files) ────────────────────
  // [0]  given name
  // [1]  family name
  // [2]  nil  (affix / aka — usually nil)
  // [3]  nil  (company — usually nil in modern BBDB)
  // [4]  tags  ("anu" "family group" ...)
  // [5]  phones  (["label" "number"] ...)
  // [6]  addresses  (["label" ("street"...) city state zip country] ...)
  // [7]  emails  ("addr1" "addr2" ...)
  // [8]  xfields alist  ((url . "...") (birthday . "1960-12-30") ...)
  // [9]  uuid string
  // [10] created timestamp
  // [11] updated timestamp

  final firstName = _str(items[0]);
  final lastName = _str(items[1]);

  // [4] tags
  final tags = _strList(items[4]);

  // [5] phones
  final phones = _parsePhones(items[5]);

  // [6] addresses
  final addresses = _parseAddresses(items[6]);

  // [7] emails
  final emails = _strList(items[7])
      .where((e) => e.isNotEmpty)
      .map((e) => ContactField(label: 'email', value: e))
      .toList();

  // [8] xfields alist
  String? url;
  DateTime? birthday;

  if (items.length > 8 && items[8] is _ListToken) {
    for (final entry in (items[8] as _ListToken).items) {
      if (entry is _ConsToken) {
        switch (entry.key) {
          case 'url':
            url = entry.value;
          case 'birthday':
            birthday = _parseDate(entry.value);
          default:
            break;
        }
      }
    }
  }

  // [9] uuid
  final uuid = items.length > 9 ? _str(items[9]) : null;

  // [10] createdAt, [11] updatedAt
  final createdAt = items.length > 10 ? _parseDate(_str(items[10])) : null;
  final updatedAt = items.length > 11 ? _parseDate(_str(items[11])) : null;

  if (firstName == null && lastName == null && emails.isEmpty) return null;

  return Contact(
    id: uuid,
    bookName: bookName,
    firstName: firstName,
    lastName: lastName,
    emails: emails,
    phones: phones,
    addresses: addresses,
    urls: url != null ? [ContactField(label: 'url', value: url)] : [],
    tags: tags,
    birthday: birthday,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
  );
}

// ── Phone parser ──────────────────────────────────────────────────────────────
// Each phone is ["label" "number"] or ["label" digits as ints...]

List<ContactField> _parsePhones(dynamic token) {
  if (token is! _ListToken) return [];
  final result = <ContactField>[];
  for (final entry in token.items) {
    if (entry is! _ListToken || entry.items.isEmpty) continue;
    final label = _str(entry.items[0]) ?? 'phone';
    // Number may be a quoted string or a series of integer tokens.
    String number = '';
    for (var i = 1; i < entry.items.length; i++) {
      final part = entry.items[i];
      if (part is _StringToken) {
        number = part.value;
        break;
      } else if (part is _NumberToken) {
        number += part.value;
      }
    }
    if (number.isNotEmpty) {
      result.add(ContactField(label: label, value: number));
    }
  }
  return result;
}

// ── Address parser ────────────────────────────────────────────────────────────
// Each address: ["label" ("street line 1" "line 2"...) "city" "state" "zip" "country"]

List<ContactAddress> _parseAddresses(dynamic token) {
  if (token is! _ListToken) return [];
  final result = <ContactAddress>[];
  for (final entry in token.items) {
    if (entry is! _ListToken || entry.items.isEmpty) continue;
    final label = _str(entry.items[0]) ?? 'address';
    // item[1] is a list of street lines.
    String? street;
    if (entry.items.length > 1 && entry.items[1] is _ListToken) {
      final lines = _strList(entry.items[1]);
      street = lines.join(', ');
    }
    final city = entry.items.length > 2 ? _str(entry.items[2]) : null;
    final state = entry.items.length > 3 ? _str(entry.items[3]) : null;
    final postcode = entry.items.length > 4 ? _str(entry.items[4]) : null;
    final country = entry.items.length > 5 ? _str(entry.items[5]) : null;

    result.add(
      ContactAddress(
        label: label,
        street: street,
        city: city,
        state: state,
        postcode: postcode,
        country: country,
      ),
    );
  }
  return result;
}

// ── Date parser ───────────────────────────────────────────────────────────────

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  // Try ISO date "1960-12-30" or datetime "2020-12-26 00:47:19 +0000".
  try {
    return DateTime.parse(s.replaceFirst(RegExp(r' \+\d{4}$'), 'Z'));
  } catch (_) {
    return null;
  }
}

// ── Token helpers ─────────────────────────────────────────────────────────────

String? _str(dynamic token) {
  if (token is _StringToken) return token.value.isEmpty ? null : token.value;
  if (token is _NilToken) return null;
  return null;
}

List<String> _strList(dynamic token) {
  if (token is _NilToken) return [];
  if (token is! _ListToken) return [];
  return token.items
      .whereType<_StringToken>()
      .map((t) => t.value)
      .where((s) => s.isNotEmpty)
      .toList();
}

// ══════════════════════════════════════════════════════════════════════════════
// Recursive tokeniser
//
// Produces a tree of typed tokens from a BBDB record string.
// ══════════════════════════════════════════════════════════════════════════════

abstract class _Token {}

class _StringToken extends _Token {
  final String value;
  _StringToken(this.value);
  @override
  String toString() => '"$value"';
}

class _NumberToken extends _Token {
  final String value;
  _NumberToken(this.value);
  @override
  String toString() => value;
}

class _NilToken extends _Token {
  @override
  String toString() => 'nil';
}

/// A parenthesised or bracketed list: (...) or [...]
class _ListToken extends _Token {
  final List<_Token> items;
  _ListToken(this.items);
  @override
  String toString() => '(${items.join(' ')})';
}

/// A cons cell: (key . "value")
class _ConsToken extends _Token {
  final String key;
  final String value;
  _ConsToken(this.key, this.value);
  @override
  String toString() => '($key . "$value")';
}

List<_Token> _tokenise(String input) {
  final cursor = _Cursor(input);
  final tokens = <_Token>[];
  cursor.skipWhitespace();
  while (!cursor.done) {
    final t = _parseToken(cursor);
    if (t != null) tokens.add(t);
    cursor.skipWhitespace();
  }
  return tokens;
}

_Token? _parseToken(_Cursor c) {
  c.skipWhitespace();
  if (c.done) return null;
  final ch = c.peek();

  if (ch == '"') return _parseString(c);
  if (ch == '(') return _parseParenList(c);
  if (ch == '[') return _parseBracketList(c);
  // nil must be followed by whitespace or a closing bracket, not more letters.
  if (ch == 'n' && c.peekN(3) == 'nil') {
    final after = c.peekN(4);
    if (after.length < 4 || ' \t\n\r)]'.contains(after[3])) {
      c.advance(3);
      return _NilToken();
    }
  }
  // Number or symbol/atom.
  return _parseAtom(c);
}

_StringToken _parseString(_Cursor c) {
  c.advance(1); // consume opening "
  final buf = StringBuffer();
  while (!c.done) {
    final ch = c.peek();
    if (ch == '\"') {
      c.advance(1);
      break;
    }
    if (ch == '\\') {
      c.advance(1);
      if (!c.done) {
        buf.write(c.peek());
        c.advance(1);
      }
    } else {
      buf.write(ch);
      c.advance(1);
    }
  }
  return _StringToken(buf.toString());
}

/// Parse (...) — may be a regular list or a cons cell (key . "val").
_Token _parseParenList(_Cursor c) {
  c.advance(1); // consume (
  final items = <_Token>[];
  c.skipWhitespace();

  while (!c.done && c.peek() != ')') {
    final t = _parseToken(c);
    if (t != null) items.add(t);
    c.skipWhitespace();

    // Check for cons dot: (symbol . "value")
    if (!c.done && c.peek() == '.' && items.length == 1) {
      c.advance(1); // consume .
      c.skipWhitespace();
      final val = _parseToken(c);
      c.skipWhitespace();
      if (!c.done && c.peek() == ')') c.advance(1);
      // Build a cons cell — key may be an unquoted atom (e.g. url, birthday).
      final keyToken = items.first;
      final keyStr = keyToken is _StringToken ? keyToken.value : '';
      final valStr = val is _StringToken ? val.value : val?.toString() ?? '';
      return _ConsToken(keyStr, valStr);
    }
  }

  if (!c.done && c.peek() == ')') c.advance(1);
  return _ListToken(items);
}

/// Parse [...] — same structure as (...).
_ListToken _parseBracketList(_Cursor c) {
  c.advance(1); // consume [
  final items = <_Token>[];
  c.skipWhitespace();
  while (!c.done && c.peek() != ']') {
    final t = _parseToken(c);
    if (t != null) items.add(t);
    c.skipWhitespace();
  }
  if (!c.done && c.peek() == ']') c.advance(1);
  return _ListToken(items);
}

/// Parse an atom: number, symbol, or nil.
_Token _parseAtom(_Cursor c) {
  final buf = StringBuffer();
  while (!c.done) {
    final ch = c.peek();
    if (ch == ' ' ||
        ch == '\t' ||
        ch == '\n' ||
        ch == '\r' ||
        ch == ')' ||
        ch == ']' ||
        ch == '(' ||
        ch == '[' ||
        ch == '"') {
      break;
    }
    buf.write(ch);
    c.advance(1);
  }
  final s = buf.toString();
  if (s == 'nil') return _NilToken();
  if (RegExp(r'^-?\d+$').hasMatch(s)) return _NumberToken(s);
  return _StringToken(s); // treat unknown atoms as strings
}

class _Cursor {
  final String _s;
  int _pos = 0;

  _Cursor(this._s);

  bool get done => _pos >= _s.length;
  String peek() => _s[_pos];
  String peekN(int n) =>
      _pos + n <= _s.length ? _s.substring(_pos, _pos + n) : '';
  void advance(int n) => _pos += n;

  void skipWhitespace() {
    while (!done) {
      final ch = _s[_pos];
      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        _pos++;
      } else {
        break;
      }
    }
  }
}
