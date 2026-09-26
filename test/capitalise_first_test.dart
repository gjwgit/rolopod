// Tests for the first-character capitalisation used by the name fields on the
// contact editor.
//
// Pure formatter plus widget behaviour — no Pod required.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:rolopod/pages/edit_field_widgets.dart';
import 'package:rolopod/utils/capitalise_first_formatter.dart';

TextEditingValue typed(String text) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CapitaliseFirstFormatter', () {
    final formatter = CapitaliseFirstFormatter();

    String format(String text) =>
        formatter.formatEditUpdate(TextEditingValue.empty, typed(text)).text;

    test('upper cases a lower case first character', () {
      expect(format('graham'), 'Graham');
    });

    test('leaves the rest of the text alone', () {
      expect(format('mcdonald'), 'Mcdonald');
      expect(format('van Dijk'), 'Van Dijk');
      expect(format('de la Cruz'), 'De la Cruz');
    });

    test('an already capitalised name is unchanged', () {
      expect(format('Williams'), 'Williams');
    });

    test('empty and non-alphabetic text are safe', () {
      expect(format(''), '');
      expect(format('3M'), '3M');
    });

    test('the cursor stays where the user left it', () {
      final result =
          formatter.formatEditUpdate(TextEditingValue.empty, typed('graham'));
      expect(result.selection.baseOffset, 6);
    });
  });

  group('EditField', () {
    testWidgets('capitalises the first character when asked', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        harness(
          EditField(
            controller: controller,
            label: 'First name',
            capitaliseFirst: true,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'graham');

      expect(controller.text, 'Graham');
    });

    testWidgets('asks the on-screen keyboard to start shifted', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        harness(
          EditField(
            controller: controller,
            label: 'First name',
            capitaliseFirst: true,
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));

      expect(field.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('leaves text alone by default', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        harness(EditField(controller: controller, label: 'Nickname')),
      );

      await tester.enterText(find.byType(TextField), 'gjw');

      expect(controller.text, 'gjw');
    });
  });
}
