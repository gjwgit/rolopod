// Tests for the address row on the contact detail card and the map provider
// preference behind it.
//
// None of this needs a live Pod: SharedPreferences and the clipboard are both
// platform channels, mocked here.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rolopod/models/contact.dart';
import 'package:rolopod/models/map_provider.dart';
import 'package:rolopod/pages/detail_widgets.dart';
import 'package:rolopod/services/view_prefs.dart';
import 'package:rolopod/widgets/map_provider_setting.dart';

const address = ContactAddress(
  label: 'home',
  street: '1 Test St',
  city: 'Canberra',
  state: 'ACT',
  postcode: '2600',
);

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('map provider', () {
    test('defaults to OpenStreetMap when nothing is stored', () async {
      expect(await ViewPrefs.mapProvider(), MapProvider.openStreetMap);
    });

    test('an unrecognised stored value falls back to the default', () {
      expect(MapProvider.fromName('bingMaps'), MapProvider.openStreetMap);
    });

    test('the chosen provider is remembered', () async {
      await ViewPrefs.setMapProvider(MapProvider.googleMaps);
      expect(await ViewPrefs.mapProvider(), MapProvider.googleMaps);
    });

    test('each provider builds an encoded search URL', () {
      expect(
        MapProvider.openStreetMap.searchUrl('1 Test St, Canberra').toString(),
        'https://www.openstreetmap.org/search?query=1%20Test%20St%2C%20Canberra',
      );
      expect(
        MapProvider.googleMaps.searchUrl('1 Test St').toString(),
        'https://www.google.com/maps/search/?api=1&query=1%20Test%20St',
      );
    });
  });

  group('address row', () {
    testWidgets('address summary is rendered as a tappable link', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const DetailAddressSection(addresses: [address])),
      );

      final text = tester.widget<Text>(find.text(address.summary));
      expect(text.style?.decoration, TextDecoration.underline);

      // The link is an InkWell, so a tap has somewhere to go.

      expect(
        find.ancestor(
          of: find.text(address.summary),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });

    testWidgets('copy button puts the address on the clipboard', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        harness(const DetailAddressSection(addresses: [address])),
      );
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pumpAndSettle();

      expect(copied, address.summary);
      expect(find.text('Address copied.'), findsOneWidget);
    });
  });

  group('map provider setting', () {
    testWidgets('shows the stored provider as selected', (tester) async {
      await ViewPrefs.setMapProvider(MapProvider.googleMaps);

      await tester.pumpWidget(harness(const MapProviderSetting()));
      await tester.pumpAndSettle();

      final button = tester.widget<SegmentedButton<MapProvider>>(
        find.byType(SegmentedButton<MapProvider>),
      );
      expect(button.selected, {MapProvider.googleMaps});
    });

    testWidgets('choosing a provider saves it', (tester) async {
      await tester.pumpWidget(harness(const MapProviderSetting()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(MapProvider.googleMaps.label));
      await tester.pumpAndSettle();

      expect(await ViewPrefs.mapProvider(), MapProvider.googleMaps);
    });
  });
}
