// Regression test for merging the last two contacts in a book.
//
// mergeDuplicates deletes both halves of the pair before re-adding the merged
// contact. That can empty the book, and upsertContact then reloads it from the
// Pod before appending, so it suspends. While mergeDuplicates was `void` the
// caller ran on and serialised the still-empty list, writing `[]` over the top
// of the merged contact.
//
// Runs without a live Pod: PodService.loadBook swallows its failure and
// returns null, which is enough to exercise the suspension.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/duplicate_detector.dart';
import 'package:rolopod/services/app_provider.dart';

const book = 'Personal';

Contact contact(String id, String first) =>
    Contact(id: id, bookName: book, firstName: first, lastName: 'Smith');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merging the last two contacts keeps the merged one', () async {
    final provider = AppProvider();
    final a = contact('a', 'Jo');
    final b = contact('b', 'Joe');

    await provider.upsertContact(a);
    await provider.upsertContact(b);
    expect(jsonDecode(provider.serialiseBook(book)) as List, hasLength(2));

    // Both halves are the entire book, so the deletes empty it.
    await provider.mergeDuplicates(
      DuplicatePair(a: a, b: b, score: 1),
      targetBook: book,
    );

    // What saveBookToPod would write. Before the fix this was [] and the
    // merged contact was lost on the Pod.
    final saved = jsonDecode(provider.serialiseBook(book)) as List;
    expect(saved, hasLength(1));
    expect((saved.single as Map)['bookName'], book);
  });

  test('merging leaves other contacts in the book untouched', () async {
    final provider = AppProvider();
    final a = contact('a', 'Jo');
    final b = contact('b', 'Joe');
    final other = contact('c', 'Pat');

    await provider.upsertContact(a);
    await provider.upsertContact(b);
    await provider.upsertContact(other);

    await provider.mergeDuplicates(
      DuplicatePair(a: a, b: b, score: 1),
      targetBook: book,
    );

    final saved = jsonDecode(provider.serialiseBook(book)) as List;
    expect(saved, hasLength(2));
    expect(
      saved.map((c) => (c as Map)['id']).toList(),
      contains('c'),
    );
  });
}
