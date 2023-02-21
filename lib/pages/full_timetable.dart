import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resentral/pages/daily_timetable.dart';

class FullTimetablePage extends StatefulWidget {
  const FullTimetablePage({super.key});

  @override
  State<FullTimetablePage> createState() => _FullTimetablePageState();
}

class _FullTimetablePageState extends State<FullTimetablePage> {
  Future<FullTimetable> _futureFullTimetable =
      Future<FullTimetable>.value(FullTimetable(weeks: List.empty()));
  String _username = '';
  String _password = '';
  String _website = '';

  Widget timetableCards() {
    List<Widget> list = <Widget>[];
    final rgbRegex = RegExp(r'(\d+), (\d+), (\d+)');

    late int red, green, blue;

    return FutureBuilder(
      future: _futureFullTimetable,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.weeks.isEmpty) {
            return const CircularProgressIndicator();
          }
          List<Widget> weekList = <Widget>[];
          for (var week in snapshot.data!.weeks) {
            List<Widget> dayList = <Widget>[];
            for (var day in week.days) {
              List<Widget> periodList = <Widget>[];
              for (var period in day.periods) {
                if (period.colour.contains('rgb')) {
                  var match = rgbRegex.firstMatch(period.colour);
                  red = int.parse(match!.group(1).toString());
                  green = int.parse(match.group(2).toString());
                  blue = int.parse(match.group(3).toString());
                } else {
                  red = 100;
                  green = 100;
                  blue = 100;
                }

                periodList.add(Container(
                  width: 10.0,
                  height: 10.0,
                  color: Color.fromARGB(255, red, green, blue),
                ));
              }
              dayList.add(Column(
                children: periodList,
              ));
            }
            weekList.add(Row(
              children: dayList,
            ));
          }
          return Column(
            children: weekList,
          );
        } else if (snapshot.hasError) {
          return Text('Try reloading (${snapshot.error})');
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _username = (prefs.getString('username') ?? '');
      _password = (prefs.getString('password') ?? '');
      _website = (prefs.getString('website') ?? '');
    });
  }

  Future<FullTimetable> getFullTimetableFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('full_timetable') != null) {
      return FullTimetable.fromJson(
          jsonDecode(prefs.getString('full_timetable')!));
    } else {
      throw Exception('Failed to fetch from local');
    }
  }

  Future<FullTimetable> fetchFullTimetable(
      String username, String password, String website) async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse('https://resentral-server.onrender.com/full_timetable'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'website': website,
      }),
    );
    if (response.statusCode == 200) {
      prefs.setString('full_timetable', response.body);
      return FullTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch: ${response.statusCode}');
    }
  }

  Future<void> setGetFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString('full_timetable') == null ||
        prefs.getString('full_timetable')!.isEmpty) {
      _loadPrefs().then((value) => _futureFullTimetable =
          fetchFullTimetable(_username, _password, _website));
    } else {
      _loadPrefs()
          .then((value) => _futureFullTimetable = getFullTimetableFromPrefs());
    }
  }

  @override
  void initState() {
    super.initState();
    setGetFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final prefs = await SharedPreferences.getInstance();
          prefs.remove('full_timetable');
          setGetFromPrefs();
        },
        color: Theme.of(context).colorScheme.onBackground,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(25.0, 50.0, 0.0, 0.0),
                alignment: Alignment.topLeft,
                child: const Text(
                  'Full Timetable',
                  style: TextStyle(
                    fontSize: 30.0,
                  ),
                ),
              ),
              const SizedBox(
                height: 40.0,
              ),
              timetableCards(),
            ],
          ),
        ),
      ),
    );
  }
}

class FullTimetable {
  const FullTimetable({
    required this.weeks,
  });

  final List<Week> weeks;

  factory FullTimetable.fromJson(Map<String, dynamic> json) => FullTimetable(
          weeks: List<Week>.from(
        json['weeks'].map((x) => Week.fromJson(x)),
      ));

  Map<String, dynamic> toJson() => {
        'weeks': List<dynamic>.from(weeks.map((x) => x.toJson())),
      };
}

class Week {
  const Week({
    required this.days,
  });

  final List<Day> days;

  factory Week.fromJson(Map<String, dynamic> json) => Week(
          days: List<Day>.from(
        json['days'].map((x) => Day.fromJson(x)),
      ));

  Map<String, dynamic> toJson() => {
        'dayss': List<dynamic>.from(days.map((x) => x.toJson())),
      };
}

class Day {
  const Day({
    required this.periods,
    required this.day,
  });

  final List<Period> periods;
  // final String day;
  final int day;

  factory Day.fromJson(Map<String, dynamic> json) => Day(
        periods:
            List<Period>.from(json['periods'].map((x) => Period.fromJson(x))),
        day: json['day'],
      );

  Map<String, dynamic> toJson() => {
        'day': day,
      };
}
