import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).colorScheme.background,
        ),
        darkTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).colorScheme.background,
        ),
        sections: [
          SettingsSection(
            title: const Text('Login and Data'),
            tiles: [
              SettingsTile.navigation(
                title: const Text('Clears All Data'),
                onPressed: (context) async {
                  final prefs = await SharedPreferences.getInstance();
                  prefs.clear();
                },
              ),
              SettingsTile.navigation(
                title: const Text('Change login'),
                enabled: false,
              ),
              SettingsTile.navigation(
                title: const Text('Change school'),
                enabled: false,
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Appearance'),
            tiles: [
              SettingsTile.navigation(
                title: const Text('Accent Colour'),
                enabled: false,
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Advanced'),
            tiles: [
              SettingsTile.navigation(
                title: const Text('Change API provider/server'),
                enabled: false,
              ),
            ],
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0.0,
        title: Text('Settings',
            style:
                TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.onBackground,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
