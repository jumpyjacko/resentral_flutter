import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController websiteController = TextEditingController();

  void _setSchoolWebsite(String website) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('website', website);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    websiteController.dispose();
    super.dispose();
  }

  Future<void> _popupSchoolWebsite() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const Text('Change school website'),
            content: Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: websiteController,
                decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Sentral URL',
                    hintText: ''),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (websiteController.text != '') {
                    _setSchoolWebsite(websiteController.text);
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          );
        });
  }

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
                title: const Text('Change Login'),
                enabled: false,
              ),
              SettingsTile.navigation(
                title: const Text('Change School/Sentral Website'),
                onPressed: (context) async {
                  _popupSchoolWebsite();
                },
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
                title: const Text('Change API Provider/Server'),
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
