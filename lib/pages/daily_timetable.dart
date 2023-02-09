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

  Widget timetableCards(Future<DailyTimetable> timetable) {
    return FutureBuilder(
      future: timetable,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          for (var periods in snapshot.data!.periods) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
              child: Text(
                periods.subject,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
            );
          }
        } else if (snapshot.hasError) {
          return Text("Try reloading (${snapshot.error})");
        }

        return const CircularProgressIndicator();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((value) =>
        futureDailyTimetable = fetchDailyTimetable(_username, _password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(25.0, 50.0, 0.0, 0.0),
            alignment: Alignment.topLeft,
            child: Text(
              "Daily Timetable",
              style: TextStyle(
                fontSize: 30.0,
              ),
            ),
          ),
          SizedBox(
            height: 40.0,
          ),
          timetableCards(futureDailyTimetable),
        ],
      ),
    );
  }
}

Future<DailyTimetable> fetchDailyTimetable(
    String username, String password) async {
  final response = await http.post(
    Uri.parse('https://resentral-server.onrender.com/daily_timetable'),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      "username": username,
      "password": password,
    }),
  );
  if (response.statusCode == 200) {
    return DailyTimetable.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch: ${response.statusCode}');
  }
}

class DailyTimetable {
  const DailyTimetable({
    required this.periods,
  });

  final List<Period> periods;

  factory DailyTimetable.fromJson(Map<String, dynamic> json) => DailyTimetable(
          periods: List<Period>.from(
        json['periods'].map((x) => Period.fromJson(x)),
      ));

  Map<String, dynamic> toJson() => {
        "periods": List<dynamic>.from(periods.map((x) => x.toJson())),
      };
}

class Period {
  const Period({
    required this.period,
    required this.subject,
    required this.subject_short,
    required this.room,
    required this.teacher,
    required this.colour,
  });

  final String period;
  final String subject;
  final String subject_short;
  final String room;
  final String teacher;
  final String colour;

  factory Period.fromJson(Map<String, dynamic> json) => Period(
        period: json['period'],
        subject: json['subject'],
        subject_short: json['subject_short'],
        room: json['room'],
        teacher: json['teacher'],
        colour: json['colour'],
      );

  Map<String, dynamic> toJson() => {
        "period": period,
        "subject": subject,
        "subject_short": subject_short,
        "room": room,
        "teacher": teacher,
        "colour": colour,
      };
}
