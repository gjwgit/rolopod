/// ViewPrefs — device-local display choices, stored in SharedPreferences.
///
// Time-stamp: <Sunday 2026-09-20 10:45:00 +1100 Graham Williams>
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

import 'package:shared_preferences/shared_preferences.dart';

import 'package:rolopod/models/map_provider.dart';

// 20260920 gjw Display choices are device preferences, never synced to the
// Pod: a stale Pod copy overwriting local on login is what made geopod's
// settings revert. Add new view preferences here rather than reaching for
// SharedPreferences directly.

class ViewPrefs {
  /// Key under which the chosen map provider is stored.

  static const String mapProviderKey = 'mapProvider';

  /// The map provider used to look up an address, OpenStreetMap by default.

  static Future<MapProvider> mapProvider() async {
    final prefs = await SharedPreferences.getInstance();

    return MapProvider.fromName(prefs.getString(mapProviderKey));
  }

  /// Remember [provider] as the map service for address lookups.

  static Future<void> setMapProvider(MapProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(mapProviderKey, provider.name);
  }
}
