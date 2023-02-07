import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // late Future<DailyTimetable> futureDailyTimetable;
  String _username = '';
  String _password = '';

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = (prefs.getString('username') ?? '');
      _password = (prefs.getString('password') ?? '');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // futureDailyTimetable = fetchDailyTimetable(_username, _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: EdgeInsets.fromLTRB(25.0, 50.0, 0.0, 0.0),
        alignment: Alignment.topLeft,
        child: const Text(
          "Announcements",
          style: TextStyle(
            fontSize: 30.0,
          ),
        ),
      ),
    );
  }
}
