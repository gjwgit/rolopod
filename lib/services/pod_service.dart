/// PodService — save and load encrypted address books on a Solid Pod.
///
// Time-stamp: <Monday 2026-03-23 06:29:29 +1100 Graham Williams>
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

import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart';

/// Service for reading and writing address books to a Solid Pod.
///
/// Each address book is stored as a Turtle (.ttl) file with the JSON
/// contact list embedded as an encrypted string literal.
///
/// File layout (relative to the app directory set in SolidLogin):
///
///   rolopod/data/Personal.ttl
///   rolopod/data/Work.ttl
///   rolopod/data/index.ttl   — list of all book filenames
///
/// The JSON payload is wrapped in a Turtle triple so the file is
/// valid Turtle and self-describing even before decryption.

class PodService {
  static const _prefixes =
      '@prefix rolopod: <https://rolopod.solidcommunity.au/ont/> .\n'
      '@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> .\n';

  // ── Turtle helpers ────────────────────────────────────────────────────────

  /// Wraps a JSON string in a Turtle document.
  static String _jsonToTtl(String predicate, String json) {
    final safe = json.replaceAll('"""', r'\"\"\"');
    return '$_prefixes\n<> rolopod:$predicate """$safe""" .\n';
  }

  /// Extracts the JSON payload from a Turtle document.
  static String? _ttlToJson(String ttl) {
    final first = ttl.indexOf('"""');
    final last = ttl.lastIndexOf('"""');
    if (first == -1 || last == first) return null;
    return ttl.substring(first + 3, last).replaceAll(r'\"\"\"', '"""');
  }

  // ── Pod file path ─────────────────────────────────────────────────────────

  /// Returns the pod-relative filename for a book, e.g. "Personal.ttl".
  static String _bookFilename(String bookName) => '$bookName.ttl';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Save [jsonContacts] (a JSON-encoded list) for [bookName] to the pod.
  ///
  /// Returns null on success, or an error message on failure.
  static Future<String?> saveBook(
    String bookName,
    String jsonContacts,
  ) async {
    try {
      final filename = _bookFilename(bookName);
      final ttl = _jsonToTtl('addressBook', jsonContacts);

      dev.log('[Pod] Writing $filename …', name: 'PodService');
      await writePod(filename, ttl, overwrite: true);
      dev.log('[Pod] Saved $filename', name: 'PodService');

      await _addToIndex(bookName);
      return null;
    } catch (e, st) {
      debugPrint('[Pod] saveBook error: $e\n$st');
      dev.log('[Pod] saveBook error: $e\n$st', name: 'PodService');
      return e.toString();
    }
  }

  /// Load the contact list for [bookName] from the pod.
  ///
  /// Returns the raw JSON string, or null if not found / on error.
  static Future<String?> loadBook(String bookName) async {
    try {
      final filename = _bookFilename(bookName);
      dev.log('[Pod] Reading $filename …', name: 'PodService');
      final ttl = await readPod(filename);
      if (ttl.isEmpty) return null;
      final json = _ttlToJson(ttl);
      dev.log('[Pod] Loaded $filename', name: 'PodService');
      return json;
    } catch (e, st) {
      debugPrint('[Pod] loadBook error ($bookName): $e\n$st');
      dev.log('[Pod] loadBook error ($bookName): $e\n$st', name: 'PodService');
      return null;
    }
  }

  /// Delete [bookName] from the pod and remove it from the index.
  ///
  /// Returns null on success, or an error message on failure.
  static Future<String?> deleteBook(String bookName) async {
    try {
      final filename = _bookFilename(bookName);
      final url = await getFileUrl('rolopod/data/$filename');
      await deleteFile(fileUrl: url);
      dev.log('[Pod] Deleted $filename', name: 'PodService');

      await _removeFromIndex(bookName);
      return null;
    } catch (e, st) {
      debugPrint('[Pod] deleteBook error ($bookName): $e\n$st');
      dev.log('[Pod] deleteBook error ($bookName): $e\n$st', name: 'PodService');
      return e.toString();
    }
  }

  /// Returns the list of address book names stored on the pod.
  static Future<List<String>> listBooks() async {
    try {
      return await _readIndex();
    } catch (e, st) {
      debugPrint('[Pod] listBooks error: $e\n$st');
      dev.log('[Pod] listBooks error: $e\n$st', name: 'PodService');
      return [];
    }
  }

  // ── Index management ──────────────────────────────────────────────────────

  static Future<List<String>> _readIndex() async {
    try {
      final ttl = await readPod('index.ttl');
      if (ttl.isEmpty) return [];
      final json = _ttlToJson(ttl);
      if (json == null) return [];
      return List<String>.from(jsonDecode(json) as List? ?? []);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeIndex(List<String> books) async {
    final ttl = _jsonToTtl('bookIndex', jsonEncode(books));
    await writePod('index.ttl', ttl, overwrite: true);
    dev.log('[Pod] Updated index.ttl: $books', name: 'PodService');
  }

  static Future<void> _addToIndex(String bookName) async {
    final index = await _readIndex();
    if (!index.contains(bookName)) {
      index.add(bookName);
      index.sort();
      await _writeIndex(index);
    }
  }

  static Future<void> _removeFromIndex(String bookName) async {
    final index = await _readIndex();
    index.remove(bookName);
    await _writeIndex(index);
  }
}
