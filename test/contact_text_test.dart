// Tests for the plain text copy of a contact offered on the contact card.
//
// Pure helper — no Pod required.

import 'package:flutter_test/flutter_test.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/utils/contact_text.dart';

void main() {
  group('contactAsText', () {
    test('lists the details one per line with labels', () {
      final c = Contact(
        bookName: 'Personal',
        firstName: 'Sukhdeep',
        lastName: 'Singh',
        organisation: 'Virk Horticulture',
        emails: const [ContactField(label: 'email', value: 'a@b.com')],
        phones: const [ContactField(label: 'mobile', value: '+61 4 7066')],
        birthday: DateTime(1980, 3, 7),
        notes: 'Gardens and lawns.',
      );

      expect(
        contactAsText(c),
        'Sukhdeep Singh\n'
        'Virk Horticulture\n'
        'a@b.com (email)\n'
        '+61 4 7066 (mobile)\n'
        'Birthday: 7/3/1980\n'
        '\nGardens and lawns.',
      );
    });

    test('omits empty fields and blank labels', () {
      final c = Contact(
        bookName: 'Personal',
        firstName: 'Ann',
        phones: const [ContactField(label: '', value: '123')],
        notes: '  ',
      );

      expect(contactAsText(c), 'Ann\n123');
    });
  });
}
