import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:after_layout/after_layout.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';

import 'dart:convert';

import 'package:resentral/pages/daily_timetable.dart';
import 'package:resentral/pages/announcements.dart';
import 'package:resentral/pages/settings.dart';
import 'package:resentral/pages/login.dart';
import 'package:resentral/pages/about.dart';

void main() {
  runApp(const MyApp());
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
    const Center(child: Text('Will be something, don\'t know what though.')),
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
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      throw Exception('Failed to update. Details: $e');
    }
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
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications),
                label: 'Something',
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: Theme.of(context).colorScheme.onBackground,
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage())),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.more_vert),
          //   color: Theme.of(context).colorScheme.onBackground,
          //   tooltip: 'Refresh',
          //   onPressed: () => Navigator.of(context).push(
          //       MaterialPageRoute(builder: (context) => const AboutPage())),
          // )
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Theme.of(context).colorScheme.background,
            ),
            child: PopupMenuButton<int>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 1,
                  child: const Text("About"),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: const Text("Check for Updates"),
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
  String? zipballUrl;
  String? tarballUrl;
  Commit? commit;
  String? nodeId;

  GithubTags(
      {this.name, this.zipballUrl, this.tarballUrl, this.commit, this.nodeId});

  GithubTags.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    zipballUrl = json['zipball_url'];
    tarballUrl = json['tarball_url'];
    commit =
        json['commit'] != null ? new Commit.fromJson(json['commit']) : null;
    nodeId = json['node_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['zipball_url'] = this.zipballUrl;
    data['tarball_url'] = this.tarballUrl;
    if (this.commit != null) {
      data['commit'] = this.commit!.toJson();
    }
    data['node_id'] = this.nodeId;
    return data;
  }
}

class Commit {
  String? sha;
  String? url;

  Commit({this.sha, this.url});

  Commit.fromJson(Map<String, dynamic> json) {
    sha = json['sha'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sha'] = this.sha;
    data['url'] = this.url;
    return data;
  }
}
