import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:after_layout/after_layout.dart';

import 'package:resentral/pages/daily_timetable.dart';
import 'package:resentral/pages/announcements.dart';
import 'package:resentral/pages/settings.dart';
import 'package:resentral/pages/login.dart';

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
  bool inSettings = false;

  final screens = [
    const DailyTimetablePage(),
    const AnnouncementsPage(),
    const Center(child: Text("other")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: inSettings ? const SettingsPage() : screens[index],
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
          IconButton(
            icon: const Icon(Icons.replay),
            color: Theme.of(context).colorScheme.onBackground,
            tooltip: 'Refresh',
            onPressed: () {},
          )
        ],
      ),
    );
  }
}
