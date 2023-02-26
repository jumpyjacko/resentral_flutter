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
    final rgbRegex = RegExp(r'(\d+), (\d+), (\d+)');

    late int red, green, blue, markerHeight;

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
                  markerHeight = 70;
                } else {
                  red = 100;
                  green = 100;
                  blue = 100;
                  markerHeight = 20;
                }

                periodList.add(Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        child: Text(
                          period.period,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withAlpha(150),
                          ),
                        ),
                      ),
                      Container(
                        width: 5.0,
                        height: markerHeight.toDouble(),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, red, green, blue),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      period.colour.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    period.subjectShort
                                        .replaceAll(RegExp(r'[()]'), ''),
                                    style: const TextStyle(fontSize: 14.0),
                                  ),
                                  Text(
                                    period.room,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withAlpha(150),
                                    ),
                                  ),
                                  const SizedBox(height: 5.0),
                                  Text(
                                    period.teacher,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground
                                          .withAlpha(150),
                                    ),
                                  )
                                ],
                              ),
                            ),
                    ],
                  ),
                ));
              }
              periodList.insert(
                0,
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 10.0),
                  child: Text(
                    day.day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withAlpha(150),
                    ),
                  ),
                ),
              );
              dayList.add(Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: periodList,
              ));
            }
            weekList.add(SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dayList,
              ),
            ));
            weekList.add(const SizedBox(height: 75.0));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: weekList,
            ),
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
    } else if (response.statusCode == 502) {
      throw Exception(
          'Failed to fetch: ${response.statusCode}\nCheck if your login/website is correct');
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
        'days': List<dynamic>.from(days.map((x) => x.toJson())),
      };
}

class Day {
  const Day({
    required this.periods,
    required this.day,
  });

  final List<Period> periods;
  final String day;

  factory Day.fromJson(Map<String, dynamic> json) => Day(
        periods:
            List<Period>.from(json['periods'].map((x) => Period.fromJson(x))),
        day: json['day'],
      );

  Map<String, dynamic> toJson() => {
        'day': day,
      };
}
