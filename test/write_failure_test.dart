// Tests that a Pod write fired from a synchronous UI callback reports its
// failure instead of dropping it, via SolidWriteFailures.watch.
//
// Runs without a live Pod: the save is stubbed by a fake provider that
// returns the error-string convention saveBookToPod uses (null on success).

import 'package:flutter_test/flutter_test.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/services/app_provider.dart';

/// Provider that never touches the Pod. [error] is what saveBookToPod
/// completes with — null for a successful save.

class FakeProvider extends AppProvider {
  FakeProvider({this.error});

  final String? error;

  @override
  Future<String?> saveBookToPod(String bookName) async => error;
}

void main() {
  setUp(SolidWriteFailures.clear);

  test('a save completing with an error String is reported', () async {
    final provider = FakeProvider(error: 'Pod unreachable');
    SolidWriteFailures.watch(
      provider.saveBookToPod('Personal'),
      during: 'deleting the contact',
    );
    await Future<void>.delayed(Duration.zero);

    expect(SolidWriteFailures.latest.value, contains('Pod unreachable'));
    expect(
      SolidWriteFailures.latest.value,
      contains('Failed deleting the contact.'),
    );
  });

  test('a save completing with null reports nothing', () async {
    final provider = FakeProvider();
    SolidWriteFailures.watch(
      provider.saveBookToPod('Personal'),
      during: 'merging the duplicates',
    );
    await Future<void>.delayed(Duration.zero);

    expect(SolidWriteFailures.latest.value, isNull);
  });

  test('a save that throws is reported', () async {
    SolidWriteFailures.watch(
      Future<String?>.error(StateError('boom')),
      during: 'merging the duplicates',
    );
    await Future<void>.delayed(Duration.zero);

    expect(SolidWriteFailures.latest.value, contains('boom'));
  });
}
