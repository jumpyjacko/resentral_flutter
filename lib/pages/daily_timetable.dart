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
  Future<DailyTimetable> _futureDailyTimetable =
      Future<DailyTimetable>.value(DailyTimetable(periods: List.empty()));
  String _username = '';
  String _password = '';
  String _website = '';

  Widget timetableCards() {
    List<Widget> list = <Widget>[];
    final rgbRegex = RegExp(r'(\d+), (\d+), (\d+)');

    late int red, green, blue;

    return FutureBuilder(
      future: _futureDailyTimetable,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.periods.isEmpty) {
            return const CircularProgressIndicator();
          }
          for (var period in snapshot.data!.periods) {
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
            list.add(
              SizedBox(
                  height: period.subject != '' ? 120.0 : 40.0,
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        child: Text(
                          period.period,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 5.0,
                        height: period.subject != '' ? 100.0 : 20.0,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(255, red, green, blue),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5))),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 17.0),
                          Text(
                            period.subject,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            period.subject_short,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withAlpha(150)),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            period.room != '' ? 'In ${period.room}' : '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            period.teacher != ' '
                                ? 'With ${period.teacher}'
                                : '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  )),
            );
          }
          return Column(children: list);
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

  Future<DailyTimetable> getDailyTimetableFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList('daily_timetable') != null) {
      return DailyTimetable.fromJson(
          jsonDecode(prefs.getStringList('daily_timetable')!.first));
    } else {
      throw Exception('Failed to fetch from local');
    }
  }

  Future<DailyTimetable> fetchDailyTimetable(
      String username, String password, String website) async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse('https://resentral-server.onrender.com/daily_timetable'),
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
      prefs.setStringList(
          'daily_timetable', [response.body, DateTime.now().toString()]);
      return DailyTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch: ${response.statusCode}');
    }
  }

  Future<void> setGetFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList('daily_timetable') != null &&
        DateTime.parse(prefs.getStringList('daily_timetable')!.last).day !=
            DateTime.now().day) {
      prefs.remove('daily_timetable');
    }

    if (prefs.getStringList('daily_timetable') == null ||
        prefs.getStringList('daily_timetable')!.isEmpty) {
      _loadPrefs().then((value) => _futureDailyTimetable =
          fetchDailyTimetable(_username, _password, _website));
    } else {
      _loadPrefs().then(
          (value) => _futureDailyTimetable = getDailyTimetableFromPrefs());
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
          prefs.remove('daily_timetable');
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
                  'Daily Timetable',
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
        'periods': List<dynamic>.from(periods.map((x) => x.toJson())),
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
        'period': period,
        'subject': subject,
        'subject_short': subject_short,
        'room': room,
        'teacher': teacher,
        'colour': colour,
      };
}
