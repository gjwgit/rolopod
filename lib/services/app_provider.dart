/// AppProvider — central state management for RoloPod.
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:rolopod/constants/app.dart';
import 'package:rolopod/models/address_book.dart';
import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/duplicate_detector.dart';
import 'package:rolopod/services/pod_service.dart';

enum AppState { idle, loading, loaded, error }

class AppProvider extends ChangeNotifier {
  AppState _state = AppState.idle;
  String? _errorMessage;

  /// All address books (owned + shared with me).
  final List<AddressBook> _books = [];

  /// All loaded contacts, keyed by book name.
  final Map<String, List<Contact>> _contactsByBook = {};

  /// Current regex search pattern.
  String _searchPattern = '';

  AppProvider() {
    // Ensure the default Personal book always exists.
    _books.add(
      AddressBook(
        name: defaultBookName,
        podPath: '$podBooksPath/$defaultBookName.json',
        ownerWebId: '',
      ),
    );
  }

  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  List<AddressBook> get books => List.unmodifiable(_books);
  String get searchPattern => _searchPattern;

  /// Contacts from all currently visible books, sorted by name.
  List<Contact> get visibleContacts {
    final visible = _books.where((b) => b.isVisible).map((b) => b.name).toSet();
    final all = _contactsByBook.entries
        .where((e) => visible.contains(e.key))
        .expand((e) => e.value)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (_searchPattern.isEmpty) return all;

    try {
      final re = RegExp(_searchPattern, caseSensitive: false);
      return all.where((c) => _matchesSearch(c, re)).toList();
    } catch (_) {
      // Invalid regex — return unfiltered.
      return all;
    }
  }

  /// All unique tags across every contact in all books, sorted.
  List<String> get allTags => _contactsByBook.values
      .expand((contacts) => contacts)
      .expand((c) => c.tags)
      .toSet()
      .toList()
    ..sort();

  /// The primary (default) address book.
  AddressBook? get primaryBook => _books.isEmpty
      ? null
      : _books.firstWhere(
          (b) => b.name == defaultBookName,
          orElse: () => _books.first,
        );

  void setSearchPattern(String pattern) {
    _searchPattern = pattern;
    notifyListeners();
  }

  void toggleBookVisibility(String bookName) {
    final book = _books.firstWhere((b) => b.name == bookName);
    book.isVisible = !book.isVisible;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Contact CRUD ───────────────────────────────────────────────────────────

  /// Find a contact by id across all books, or null if not found.
  Contact? findContactById(String id) {
    for (final list in _contactsByBook.values) {
      for (final c in list) {
        if (c.id == id) return c;
      }
    }
    return null;
  }

  /// Find the first contact whose name fuzzy-matches [name], or null.
  Contact? findContactByName(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    // Exact match first.
    for (final list in _contactsByBook.values) {
      for (final c in list) {
        if (c.name.toLowerCase() == needle) return c;
      }
    }
    // Partial match fallback.
    for (final list in _contactsByBook.values) {
      for (final c in list) {
        if (c.name.toLowerCase().contains(needle) ||
            needle.contains(c.name.toLowerCase())) {
          return c;
        }
      }
    }
    return null;
  }

  /// Add or update a contact.
  void upsertContact(Contact contact) {
    final list = _contactsByBook.putIfAbsent(contact.bookName, () => []);
    final idx = list.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      list[idx] = contact;
    } else {
      list.add(contact);
    }
    notifyListeners();
  }

  /// Delete a contact by id.
  void deleteContact(String id) {
    for (final list in _contactsByBook.values) {
      list.removeWhere((c) => c.id == id);
    }
    notifyListeners();
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Import a list of contacts into a named book.
  void importContacts(List<Contact> contacts, {required String bookName}) {
    // Ensure the book exists in the list so it appears in the UI.
    if (!_books.any((b) => b.name == bookName)) {
      _books.add(
        AddressBook(
          name: bookName,
          podPath: '$podBooksPath/$bookName.json',
          ownerWebId: '',
        ),
      );
    }
    final list = _contactsByBook.putIfAbsent(bookName, () => []);
    list.addAll(contacts);
    debugPrint(
      '[AppProvider] Imported ${contacts.length} contacts into $bookName',
    );
    notifyListeners();
  }

  // ── Address books ──────────────────────────────────────────────────────────

  void addBook(AddressBook book) {
    if (!_books.any((b) => b.name == book.name)) {
      _books.add(book);
      notifyListeners();
    }
  }

  // ── Duplicates ─────────────────────────────────────────────────────────────

  /// Find fuzzy-name duplicates across all visible contacts.
  List<DuplicatePair> scanForDuplicates() {
    return findDuplicates(visibleContacts);
  }

  /// Merge a duplicate pair — keeps [primary], deletes [secondary].
  void mergeDuplicates(DuplicatePair pair, {required String targetBook}) {
    final merged = mergeContacts(pair.a, pair.b, bookName: targetBook);
    deleteContact(pair.a.id);
    deleteContact(pair.b.id);
    upsertContact(merged);
  }

  // ── Pod save / load ────────────────────────────────────────────────────────

  /// Save [bookName] contacts to the pod.
  ///
  /// Returns null on success, or an error message on failure.
  Future<String?> saveBookToPod(String bookName) async {
    final json = serialiseBook(bookName);
    final error = await PodService.saveBook(bookName, json);
    if (error != null) {
      _errorMessage = 'Failed to save "$bookName": $error';
      _state = AppState.error;
      notifyListeners();
    }
    return error;
  }

  /// Load all address books listed on the pod into memory.
  Future<void> loadAllBooksFromPod() async {
    _state = AppState.loading;
    notifyListeners();

    try {
      final bookNames = await PodService.listBooks();

      // Always ensure Personal exists locally even if not yet on pod.
      if (!bookNames.contains(defaultBookName)) {
        bookNames.insert(0, defaultBookName);
      }

      for (final name in bookNames) {
        // Ensure book is registered locally.
        if (!_books.any((b) => b.name == name)) {
          _books.add(
            AddressBook(
              name: name,
              podPath: 'rolopod/data/$name.ttl',
              ownerWebId: '',
            ),
          );
        }
        // Load contacts from pod.
        final json = await PodService.loadBook(name);
        if (json != null) deserialiseBook(name, json);
      }

      _state = AppState.loaded;
    } catch (e, st) {
      debugPrint('[AppProvider] loadAllBooksFromPod error: $e\n$st');
      _errorMessage = 'Failed to load address books: $e';
      _state = AppState.error;
    }

    notifyListeners();
  }

  /// Save all books to the pod (e.g. after import or edit).
  Future<void> saveAllBooksToPod() async {
    for (final book in _books) {
      if (!book.isSharedWithMe) await saveBookToPod(book.name);
    }
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// Serialise all contacts in [bookName] to JSON string.
  String serialiseBook(String bookName) {
    final contacts = _contactsByBook[bookName] ?? [];
    return jsonEncode(contacts.map((c) => c.toJson()).toList());
  }

  /// Load contacts from JSON string into [bookName].
  void deserialiseBook(String bookName, String json) {
    try {
      final list = jsonDecode(json) as List;
      _contactsByBook[bookName] =
          list.map((j) => Contact.fromJson(j as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e, st) {
      debugPrint('[AppProvider] deserialise error: $e\n$st');
      _errorMessage = 'Failed to load address book: $e';
      _state = AppState.error;
      notifyListeners();
    }
  }

  // ── Search helper ──────────────────────────────────────────────────────────

  bool _matchesSearch(Contact c, RegExp re) {
    // Support tag:foo syntax to filter by tag.
    final pattern = re.pattern;
    if (pattern.startsWith('tag:')) {
      final tag = pattern.substring(4).toLowerCase();
      return c.tags.any((t) => t.toLowerCase().contains(tag));
    }
    return re.hasMatch(c.name) ||
        re.hasMatch(c.organisation ?? '') ||
        c.emails.any((e) => re.hasMatch(e.value)) ||
        c.phones.any((p) => re.hasMatch(p.value)) ||
        c.tags.any((t) => re.hasMatch(t)) ||
        re.hasMatch(c.notes ?? '');
  }
}
