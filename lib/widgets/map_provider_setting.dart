/// MapProviderSetting — choose the map service used for address lookups.
///
// Time-stamp: <Sunday 2026-09-20 10:55:00 +1100 Graham Williams>
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

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:rolopod/models/map_provider.dart';
import 'package:rolopod/services/view_prefs.dart';

class MapProviderSetting extends StatefulWidget {
  const MapProviderSetting({super.key});

  @override
  State<MapProviderSetting> createState() => _MapProviderSettingState();
}

class _MapProviderSettingState extends State<MapProviderSetting> {
  // 20260920 gjw Start on the default so the control renders immediately;
  // the stored choice replaces it as soon as the preference is read.

  MapProvider _provider = MapProvider.openStreetMap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await ViewPrefs.mapProvider();
    if (mounted) setState(() => _provider = stored);
  }

  Future<void> _select(MapProvider provider) async {
    setState(() => _provider = provider);
    await ViewPrefs.setMapProvider(provider);
  }

  @override
  Widget build(BuildContext context) => MarkdownTooltip(
        message: '**Map Service**\n\n'
            'Choose which map opens when you tap an address on a contact '
            'card. **OpenStreetMap** is the open-data default; '
            '**Google Maps** often resolves partial addresses better.',
        child: SegmentedButton<MapProvider>(
          segments: MapProvider.values
              .map(
                (p) => ButtonSegment<MapProvider>(
                  value: p,
                  label: Text(p.label),
                ),
              )
              .toList(),
          selected: {_provider},
          onSelectionChanged: (s) => _select(s.first),
        ),
      );
}
