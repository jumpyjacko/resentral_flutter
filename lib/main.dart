import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:after_layout/after_layout.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';

import 'dart:convert';

import 'package:resentral/pages/daily_timetable.dart';
import 'package:resentral/pages/announcements.dart';
import 'package:resentral/pages/full_timetable.dart';
import 'package:resentral/pages/settings.dart';
import 'package:resentral/pages/login.dart';
import 'package:resentral/pages/about.dart';

void main() {
  runApp(const MyApp());
}

class ScrollBehaviorModified extends ScrollBehavior {
  const ScrollBehaviorModified();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return const BouncingScrollPhysics();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const ClampingScrollPhysics();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'reSentral',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.black),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          background: Colors.grey.shade50,
          onBackground: Colors.black,
          primary: Colors.lightBlue.shade200,
          onPrimary: Colors.white,
          secondary: Colors.lightBlue.shade50,
        ),
      ),
      darkTheme: ThemeData(
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          background: const Color.fromARGB(255, 27, 27, 27),
          onBackground: Colors.white,
          primary: Colors.blue.shade200,
          onPrimary: Colors.white,
          secondary: Colors.blue.shade50,
        ),
      ),
      builder: (context, widget) {
        return ScrollConfiguration(
            behavior: ScrollBehaviorModified(), child: widget!);
      },
      home: Splash(),
    );
  }
}

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with AfterLayoutMixin<Splash> {
  Future checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    if (_seen) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()));
    } else {
      await prefs.setBool('seen', true);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()));
    }
  }

  @override
  void afterFirstLayout(BuildContext context) => checkFirstSeen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.onBackground),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  late OtaEvent currentEvent;

  final screens = [
    DailyTimetablePage(key: UniqueKey()),
    AnnouncementsPage(key: UniqueKey()),
    FullTimetablePage(key: UniqueKey()),
  ];

  Future<String> checkUpdateExists(bool startup) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    late GithubTags remoteVersion;

    final response = await http.get(
      Uri.parse(
          'https://api.github.com/repos/jumpyjacko/resentral_flutter/tags'),
    );

    if (response.statusCode == 200) {
      remoteVersion = GithubTags.fromJson(jsonDecode(response.body)[0]);
    } else {
      throw Exception('Failed to fetch: ${response.statusCode}');
    }

    if (remoteVersion.name.toString() == packageInfo.version && !startup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No new update!',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      );
      return '';
    } else if (remoteVersion.name.toString() == packageInfo.version &&
        startup) {
      return '';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'There\'s a new update!',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          action: SnackBarAction(
            label: 'Update',
            onPressed: () => tryOtaUpdate(),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      );
      return remoteVersion.name.toString();
    }
  }

  Future<void> tryOtaUpdate() async {
    final update = await checkUpdateExists(false);
    if (update.isEmpty) {
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloading update...',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      );
      OtaUpdate()
          .execute(
        'https://github.com/JumpyJacko/resentral_flutter/releases/download/$update/app-release.apk',
        destinationFilename: 'app-release.apk',
      )
          .listen(
        (OtaEvent event) {
          setState(() => currentEvent = event);
        },
      );
    } catch (e) {
      throw Exception('Failed to update. Details: $e');
    }
  }

  Future<void> tryGithubChangelogs() async {
    late GithubReleaseLatest releaseLatest;
    final response = await http.get(
      Uri.parse(
          'https://api.github.com/repos/jumpyjacko/resentral_flutter/releases/latest'),
    );
    if (response.statusCode == 200) {
      releaseLatest = GithubReleaseLatest.fromJson(jsonDecode(response.body));
      await popupGithubChangelogs(releaseLatest);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to get changelogs, try again',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      );
      throw Exception('Failed to fetch: ${response.statusCode}');
    }
  }

  Future<void> popupGithubChangelogs(GithubReleaseLatest response) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.background,
            scrollable: true,
            title: Text(
              'Latest Changelogs - \n${response.name}',
              style: const TextStyle(fontSize: 20.0),
            ),
            content: Text(response.body.toString(),
                style: const TextStyle(fontSize: 14.0)),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    checkUpdateExists(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: screens[index],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 50, right: 50),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Theme.of(context).colorScheme.background,
            indicatorColor: Theme.of(context).colorScheme.primary.withAlpha(50),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            height: 100.0,
          ),
          child: NavigationBar(
            shadowColor: Colors.transparent,
            selectedIndex: index,
            onDestinationSelected: (index) =>
                setState(() => this.index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'Daily Timetable',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: 'Announcements',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_timeline_outlined),
                selectedIcon: Icon(Icons.view_timeline),
                label: 'Full Timetable',
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).colorScheme.background,
          systemNavigationBarColor: Theme.of(context).colorScheme.background,
          statusBarBrightness: Theme.of(context).brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
        ),
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: Theme.of(context).colorScheme.onBackground,
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage())),
        ),
        actions: [
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Theme.of(context).colorScheme.background,
            ),
            child: PopupMenuButton<int>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: Text("About"),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Text("Check for Updates"),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Text("Changelogs"),
                ),
              ],
              offset: Offset(0, AppBar().preferredSize.height),
              onSelected: (value) {
                switch (value) {
                  case 1:
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AboutPage()));
                    break;
                  case 2:
                    tryOtaUpdate();
                    break;
                  case 3:
                    tryGithubChangelogs();
                    break;
                  default:
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Auto-generated, check out https://javiercbk.github.io/json_to_dart/
class GithubTags {
  String? name;

  GithubTags({this.name});

  GithubTags.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    return data;
  }
}

class GithubReleaseLatest {
  String? name;
  String? body;

  GithubReleaseLatest({this.name, this.body});

  GithubReleaseLatest.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['body'] = body;
    return data;
  }
}
