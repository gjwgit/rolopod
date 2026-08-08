// Widget tests for SolidWindowCloseGuard as wired up by ContactEdit — the
// window-close confirmation path (save / discard / keep editing).
//
// Runs without a live Pod: only rendering / state behaviour, with the Pod
// write stubbed out by a fake provider.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/pages/contact_edit.dart';
import 'package:rolopod/services/app_provider.dart';

/// Provider that never touches the Pod. When [podWrite] is supplied the save
/// blocks on it, so a test can hold the write in flight and assert the close
/// guard has not resolved yet.

class FakeProvider extends AppProvider {
  FakeProvider({this.podWrite, this.error});

  final Completer<void>? podWrite;

  /// When set, the Pod write reports this failure instead of succeeding.

  final String? error;
  bool written = false;

  @override
  Future<void> upsertContact(Contact contact) async {}

  @override
  Future<String?> saveBookToPod(String bookName) async {
    await podWrite?.future;
    if (error != null) return error;
    written = true;
    return null;
  }
}

Widget wrap(Widget child, AppProvider provider) =>
    ChangeNotifierProvider<AppProvider>.value(
      value: provider,
      child: MaterialApp(home: child),
    );

Widget editor() => ContactEdit(
      contact: Contact(bookName: 'Personal'),
      isNew: true,
    );

void main() {
  testWidgets('resolveAll succeeds with no prompt when nothing changed',
      (tester) async {
    await tester.pumpWidget(wrap(editor(), FakeProvider()));
    await tester.pumpAndSettle();
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
    expect(find.text('Unsaved changes'), findsNothing);
  });

  testWidgets('resolveAll prompts and resolves true on Discard',
      (tester) async {
    await tester.pumpWidget(wrap(editor(), FakeProvider()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(await future, isTrue);
  });

  testWidgets('resolveAll prompts and resolves false on Keep editing',
      (tester) async {
    await tester.pumpWidget(wrap(editor(), FakeProvider()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    // The editor is still open with the unsaved first name intact.
    expect(find.text('Ada'), findsOneWidget);
  });

  // Regression: the window is destroyed the moment every resolver returns
  // true, so a fire-and-forget Pod write would be killed mid-flight and the
  // contact lost despite the user tapping Save.
  testWidgets('window-close Save waits for the Pod write to finish',
      (tester) async {
    final podWrite = Completer<void>();
    final provider = FakeProvider(podWrite: podWrite);

    await tester.pumpWidget(wrap(editor(), provider));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.pump();

    var resolved = false;
    final future = SolidWindowCloseGuard.resolveAll()
      ..then((_) => resolved = true);
    await tester.pumpAndSettle();

    // The editor behind the dialog has a Save button too, so target the
    // dialog's one specifically.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    // The Pod write is still in flight, so the guard must NOT have resolved.
    expect(resolved, isFalse);
    expect(provider.written, isFalse);

    podWrite.complete();
    await tester.pumpAndSettle();

    expect(await future, isTrue);
    expect(provider.written, isTrue);
  });

  // Regression: saveUnsavedChanges() said "saved" whatever happened, so a
  // failed Pod write still let the window close and the contact was lost —
  // exactly what the prompt exists to prevent. resolveAll() must say no.
  testWidgets('window-close Save resolves false when the Pod write fails',
      (tester) async {
    SolidWriteFailures.clear();
    addTearDown(SolidWriteFailures.clear);
    final provider = FakeProvider(error: 'Pod unreachable');

    await tester.pumpWidget(wrap(editor(), provider));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ada');
    await tester.pump();

    final future = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();

    // The editor behind the dialog has a Save button too, so target the
    // dialog's one specifically.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await future, isFalse);
    expect(
      SolidWriteFailures.latest.value,
      contains('Failed saving the contact.'),
    );
    expect(SolidWriteFailures.latest.value, contains('Pod unreachable'));

    // The editor is still open with the edit intact, and still reports it as
    // unsaved so a second close attempt prompts again.
    expect(find.text('Ada'), findsOneWidget);
    final again = SolidWindowCloseGuard.resolveAll();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(await again, isFalse);
  });

  testWidgets('editor unregisters its resolver on dispose', (tester) async {
    final provider = FakeProvider();
    await tester.pumpWidget(wrap(editor(), provider));
    await tester.pumpAndSettle();
    await tester.pumpWidget(wrap(const SizedBox(), provider));
    await tester.pumpAndSettle();
    // No editor left registered, so nothing to resolve.
    expect(await SolidWindowCloseGuard.resolveAll(), isTrue);
  });
}
