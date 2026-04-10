/// RoloPod — privacy-first address book with Solid Pod storage.
///
// Time-stamp: <Monday 2026-03-23 06:29:29 +1100 Graham Williams>
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

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:rolopod/app_scaffold.dart';
import 'package:rolopod/services/app_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SolidUI security key manager so it can automatically prompt
  // the user for their security key whenever solidpod needs it.

  SolidSecurityKeyCentralManager.instance;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const RoloPodApp(),
    ),
  );
}

class RoloPodApp extends StatefulWidget {
  const RoloPodApp({super.key});

  @override
  State<RoloPodApp> createState() => _RoloPodAppState();
}

class _RoloPodAppState extends State<RoloPodApp> {
  @override
  void initState() {
    super.initState();
    _initTheme();
    solidThemeNotifier.addListener(() => setState(() {}));
  }

  Future<void> _initTheme() async {
    await solidThemeNotifier.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoloPod',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A6478)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A6478),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: solidThemeNotifier.themeMode,
      home: SolidLogin(
        required: false,
        title: 'RoloPod'.toUpperCase().replaceAll(' - ', '\n'),
        image: const AssetImage('assets/images/app_image.jpg'),
        logo: const AssetImage('assets/images/app_icon.png'),
        link: 'https://github.com/gjwgit/rolopod',
        child: const AppScaffold(),
      ),
    );
  }
}
