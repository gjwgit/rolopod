/// RoloPod — privacy-first address book with Solid Pod storage.
///
// Time-stamp: <Sunday 2026-05-31 08:55:56 +1000 Graham Williams>
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:rolopod/app_scaffold.dart';
import 'package:rolopod/services/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 20260808 gjw Route the desktop title-bar close button through the solidui
  // close guard rather than quitting immediately, so a contact being edited
  // with unsaved changes can be saved or discarded instead of being silently
  // lost. ContactEdit registers a resolver with the guard.

  if (isDesktop) {
    await windowManager.ensureInitialized();
    await SolidWindowCloseGuard.enable();
  }

  // Initialise SolidUI security key manager so it can automatically prompt
  // the user for their security key whenever solidpod needs it.

  SolidSecurityKeyCentralManager.instance;

  // Create the AppProvider up-front so we can wire it into the solidui
  // logout flow and ensure in-memory contact data is cleared whenever a
  // user logs out.

  final appProvider = AppProvider();

  SolidAuthHandler.instance.configure(
    SolidAuthConfig(
      onLogout: appProvider.reset,
    ),
  );

  runApp(
    ChangeNotifierProvider<AppProvider>.value(
      value: appProvider,
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
        clientId: 'https://gjwgit.github.io/rolopod/client-profile.jsonld',
        redirectUris: kIsWeb
            ? ['${Uri.base.origin}/redirect.html']
            : const [
                'com.togaware.rolopod://redirect',
                'http://localhost:4400/redirect.html',
              ],
        child: const SolidWriteFailureListener(child: AppScaffold()),
      ),
    );
  }
}
