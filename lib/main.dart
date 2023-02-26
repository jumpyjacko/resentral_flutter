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
      // ignore: avoid_catches_without_on_clauses
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
            title: const Text('Latest Changelogs'),
            content: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SingleChildScrollView(
                child: Text(
                  response.body.toString(),
                ),
              ),
            ),
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
    commit = json['commit'] != null ? Commit.fromJson(json['commit']) : null;
    nodeId = json['node_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['zipball_url'] = zipballUrl;
    data['tarball_url'] = tarballUrl;
    if (commit != null) {
      data['commit'] = commit!.toJson();
    }
    data['node_id'] = nodeId;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sha'] = sha;
    data['url'] = url;
    return data;
  }
}

// Why ;-; (also auto-generated)
class GithubReleaseLatest {
  String? url;
  String? assetsUrl;
  String? uploadUrl;
  String? htmlUrl;
  int? id;
  Author? author;
  String? nodeId;
  String? tagName;
  String? targetCommitish;
  String? name;
  bool? draft;
  bool? prerelease;
  String? createdAt;
  String? publishedAt;
  List<Assets>? assets;
  String? tarballUrl;
  String? zipballUrl;
  String? body;

  GithubReleaseLatest(
      {this.url,
      this.assetsUrl,
      this.uploadUrl,
      this.htmlUrl,
      this.id,
      this.author,
      this.nodeId,
      this.tagName,
      this.targetCommitish,
      this.name,
      this.draft,
      this.prerelease,
      this.createdAt,
      this.publishedAt,
      this.assets,
      this.tarballUrl,
      this.zipballUrl,
      this.body});

  GithubReleaseLatest.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    assetsUrl = json['assets_url'];
    uploadUrl = json['upload_url'];
    htmlUrl = json['html_url'];
    id = json['id'];
    author = json['author'] != null ? Author.fromJson(json['author']) : null;
    nodeId = json['node_id'];
    tagName = json['tag_name'];
    targetCommitish = json['target_commitish'];
    name = json['name'];
    draft = json['draft'];
    prerelease = json['prerelease'];
    createdAt = json['created_at'];
    publishedAt = json['published_at'];
    if (json['assets'] != null) {
      assets = <Assets>[];
      json['assets'].forEach((v) {
        assets!.add(Assets.fromJson(v));
      });
    }
    tarballUrl = json['tarball_url'];
    zipballUrl = json['zipball_url'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['assets_url'] = assetsUrl;
    data['upload_url'] = uploadUrl;
    data['html_url'] = htmlUrl;
    data['id'] = id;
    if (author != null) {
      data['author'] = author!.toJson();
    }
    data['node_id'] = nodeId;
    data['tag_name'] = tagName;
    data['target_commitish'] = targetCommitish;
    data['name'] = name;
    data['draft'] = draft;
    data['prerelease'] = prerelease;
    data['created_at'] = createdAt;
    data['published_at'] = publishedAt;
    if (assets != null) {
      data['assets'] = assets!.map((v) => v.toJson()).toList();
    }
    data['tarball_url'] = tarballUrl;
    data['zipball_url'] = zipballUrl;
    data['body'] = body;
    return data;
  }
}

class Author {
  String? login;
  int? id;
  String? nodeId;
  String? avatarUrl;
  String? gravatarId;
  String? url;
  String? htmlUrl;
  String? followersUrl;
  String? followingUrl;
  String? gistsUrl;
  String? starredUrl;
  String? subscriptionsUrl;
  String? organizationsUrl;
  String? reposUrl;
  String? eventsUrl;
  String? receivedEventsUrl;
  String? type;
  bool? siteAdmin;

  Author(
      {this.login,
      this.id,
      this.nodeId,
      this.avatarUrl,
      this.gravatarId,
      this.url,
      this.htmlUrl,
      this.followersUrl,
      this.followingUrl,
      this.gistsUrl,
      this.starredUrl,
      this.subscriptionsUrl,
      this.organizationsUrl,
      this.reposUrl,
      this.eventsUrl,
      this.receivedEventsUrl,
      this.type,
      this.siteAdmin});

  Author.fromJson(Map<String, dynamic> json) {
    login = json['login'];
    id = json['id'];
    nodeId = json['node_id'];
    avatarUrl = json['avatar_url'];
    gravatarId = json['gravatar_id'];
    url = json['url'];
    htmlUrl = json['html_url'];
    followersUrl = json['followers_url'];
    followingUrl = json['following_url'];
    gistsUrl = json['gists_url'];
    starredUrl = json['starred_url'];
    subscriptionsUrl = json['subscriptions_url'];
    organizationsUrl = json['organizations_url'];
    reposUrl = json['repos_url'];
    eventsUrl = json['events_url'];
    receivedEventsUrl = json['received_events_url'];
    type = json['type'];
    siteAdmin = json['site_admin'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['login'] = login;
    data['id'] = id;
    data['node_id'] = nodeId;
    data['avatar_url'] = avatarUrl;
    data['gravatar_id'] = gravatarId;
    data['url'] = url;
    data['html_url'] = htmlUrl;
    data['followers_url'] = followersUrl;
    data['following_url'] = followingUrl;
    data['gists_url'] = gistsUrl;
    data['starred_url'] = starredUrl;
    data['subscriptions_url'] = subscriptionsUrl;
    data['organizations_url'] = organizationsUrl;
    data['repos_url'] = reposUrl;
    data['events_url'] = eventsUrl;
    data['received_events_url'] = receivedEventsUrl;
    data['type'] = type;
    data['site_admin'] = siteAdmin;
    return data;
  }
}

class Assets {
  String? url;
  int? id;
  String? nodeId;
  String? name;
  Null label;
  Author? uploader;
  String? contentType;
  String? state;
  int? size;
  int? downloadCount;
  String? createdAt;
  String? updatedAt;
  String? browserDownloadUrl;

  Assets(
      {this.url,
      this.id,
      this.nodeId,
      this.name,
      this.label,
      this.uploader,
      this.contentType,
      this.state,
      this.size,
      this.downloadCount,
      this.createdAt,
      this.updatedAt,
      this.browserDownloadUrl});

  Assets.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    id = json['id'];
    nodeId = json['node_id'];
    name = json['name'];
    label = json['label'];
    uploader =
        json['uploader'] != null ? Author.fromJson(json['uploader']) : null;
    contentType = json['content_type'];
    state = json['state'];
    size = json['size'];
    downloadCount = json['download_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    browserDownloadUrl = json['browser_download_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['id'] = id;
    data['node_id'] = nodeId;
    data['name'] = name;
    data['label'] = label;
    if (uploader != null) {
      data['uploader'] = uploader!.toJson();
    }
    data['content_type'] = contentType;
    data['state'] = state;
    data['size'] = size;
    data['download_count'] = downloadCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['browser_download_url'] = browserDownloadUrl;
    return data;
  }
}
