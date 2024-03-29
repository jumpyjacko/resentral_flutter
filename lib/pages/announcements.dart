import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:resentral/pages/announcements_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  Future<Announcements> _futureAnnouncements =
      Future<Announcements>.value(Announcements(announcements: List.empty()));
  String _username = '';
  String _password = '';
  String _website = '';

  Widget announcementCards() {
    List<Widget> list = <Widget>[];

    return FutureBuilder(
      future: _futureAnnouncements,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.announcements.isEmpty) {
            return const CircularProgressIndicator();
          }
          for (var announcement in snapshot.data!.announcements) {
            if (announcement.name == "Empty") {
              list.add(Column(
                children: [
                  const Text(
                    "No announcements available!\n\nPull down to refresh.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                  ),
                ],
              ));
              break;
            }
            list.add(
              InkWell(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 1.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withAlpha(75),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: const TextStyle(fontSize: 24.0),
                        ),
                        Text(
                          announcement.name,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withAlpha(175),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          announcement.body,
                          style: const TextStyle(
                            fontSize: 14.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AnnouncementsChildPage(
                            title: announcement.title,
                            name: announcement.name,
                            body: announcement.body,
                          )));
                },
              ),
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

  Future<Announcements> getAnnouncementsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList('announcements') != null) {
      return Announcements.fromJson(
          jsonDecode(prefs.getStringList('announcements')!.first));
    } else {
      throw Exception('Failed to fetch from local');
    }
  }

  Future<Announcements> fetchAnnouncements(
      String username, String password, String website) async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.post(
      Uri.parse('https://resentral-server.onrender.com/announcements'),
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
          'announcements', [response.body, DateTime.now().toString()]);
      return Announcements.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 502) {
      throw Exception(
          'Failed to fetch: ${response.statusCode}\nCheck if your login/website is correct');
    } else {
      throw Exception('Failed to fetch: ${response.statusCode}');
    }
  }

  Future<void> setGetFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList('announcements') != null &&
        DateTime.parse(prefs.getStringList('announcements')!.last).day !=
            DateTime.now().day) {
      prefs.remove('announcements');
    }

    if (prefs.getStringList('announcements') == null ||
        prefs.getStringList('announcements')!.isEmpty) {
      _loadPrefs().then((value) => _futureAnnouncements =
          fetchAnnouncements(_username, _password, _website));
    } else {
      _loadPrefs()
          .then((value) => _futureAnnouncements = getAnnouncementsFromPrefs());
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
          prefs.remove('announcements');
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
                  'Announcements',
                  style: TextStyle(
                    fontSize: 30.0,
                  ),
                ),
              ),
              const SizedBox(
                height: 40.0,
              ),
              announcementCards(),
            ],
          ),
        ),
      ),
    );
  }
}

class Announcements {
  const Announcements({
    required this.announcements,
  });

  final List<Announcement> announcements;

  factory Announcements.fromJson(Map<String, dynamic> json) => Announcements(
          announcements: List<Announcement>.from(
        json['announcements'].map((x) => Announcement.fromJson(x)),
      ));

  Map<String, dynamic> toJson() => {
        'announcements':
            List<dynamic>.from(announcements.map((x) => x.toJson())),
      };
}

class Announcement {
  const Announcement({
    required this.name,
    required this.title,
    required this.body,
  });

  final String name;
  final String title;
  final String body;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        name: json['name'],
        title: json['title'],
        body: json['body'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'body': body,
      };
}
