import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DailyTimetablePage extends StatefulWidget {
  const DailyTimetablePage({super.key});

  @override
  State<DailyTimetablePage> createState() => _DailyTimetablePageState();
}

class _DailyTimetablePageState extends State<DailyTimetablePage> {
  late Future<DailyTimetable> futureDailyTimetable;
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
    futureDailyTimetable = fetchDailyTimetable(_username, _password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: EdgeInsets.fromLTRB(25.0, 50.0, 0.0, 0.0),
        alignment: Alignment.topLeft,
        child: const Text(
          "Daily Timetable",
          style: TextStyle(
            fontSize: 30.0,
          ),
        ),
      ),
    );
  }
}

Future<DailyTimetable> fetchDailyTimetable(
    String username, String password) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/daily_timetable'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, dynamic>{
      'username': username,
      'password': password,
    }),
  );
  if (response.statusCode == 200) {
    return DailyTimetable.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch daily timetable');
  }
}

class DailyTimetable {
  final List<Period> periods;

  const DailyTimetable({
    required this.periods,
  });

  factory DailyTimetable.fromJson(Map<String, dynamic> json) {
    return DailyTimetable(
      periods: json['periods'],
    );
  }
}

class Period {
  final String period;
  final String subject;
  final String subject_short;
  final String room;
  final String teacher;
  final String colour;

  const Period({
    required this.period,
    required this.subject,
    required this.subject_short,
    required this.room,
    required this.teacher,
    required this.colour,
  });

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      period: json['period'],
      subject: json['subject'],
      subject_short: json['subject_short'],
      room: json['room'],
      teacher: json['teacher'],
      colour: json['colour'],
    );
  }
}
