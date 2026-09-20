/// MapProvider — the map service used to look up a contact's address.
///
// Time-stamp: <Sunday 2026-09-20 10:40:00 +1100 Graham Williams>
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

enum MapProvider {
  openStreetMap(
    'OpenStreetMap',
    'https://www.openstreetmap.org/search?query=',
  ),
  googleMaps(
    'Google Maps',
    'https://www.google.com/maps/search/?api=1&query=',
  );

  const MapProvider(this.label, this._searchPrefix);

  /// Name shown in Settings.

  final String label;

  /// Search URL up to and including the address parameter.

  final String _searchPrefix;

  /// Browser URL that looks [address] up on this provider.

  Uri searchUrl(String address) =>
      Uri.parse('$_searchPrefix${Uri.encodeComponent(address)}');

  /// The provider stored under [name], defaulting to OpenStreetMap.
  ///
  /// The default lives here so a missing or stale preference is never an
  /// error.

  static MapProvider fromName(String? name) => values.firstWhere(
        (p) => p.name == name,
        orElse: () => openStreetMap,
      );
}
