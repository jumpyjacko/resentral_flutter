import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:ota_update/ota_update.dart';

import 'dart:convert';

Future<String> checkUpdateExists(bool startup, BuildContext context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  late GithubTags remoteVersion;

  final response = await http.get(
    Uri.parse('https://api.github.com/repos/jumpyjacko/resentral_flutter/tags'),
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
  } else if (remoteVersion.name.toString() == packageInfo.version && startup) {
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
          onPressed: () => tryOtaUpdate(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
    );
    return remoteVersion.name.toString();
  }
}

Future<void> tryOtaUpdate(BuildContext context) async {
  final update = await checkUpdateExists(false, context);
  late OtaEvent currentEvent;

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
        currentEvent = event;
      },
    );
  } catch (e) {
    throw Exception('Failed to update. Details: $e');
  }
}

Future<void> tryGithubChangelogs(BuildContext context) async {
  late GithubReleaseLatest releaseLatest;
  final response = await http.get(
    Uri.parse(
        'https://api.github.com/repos/jumpyjacko/resentral_flutter/releases/latest'),
  );
  if (response.statusCode == 200) {
    releaseLatest = GithubReleaseLatest.fromJson(jsonDecode(response.body));
    await popupGithubChangelogs(releaseLatest, context);
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

Future<void> popupGithubChangelogs(
    GithubReleaseLatest response, BuildContext context) async {
  return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          scrollable: true,
          title: Text(
            'Latest Changelogs - \n${response.name}',
            style: const TextStyle(fontSize: 20.0),
          ),
          content: Text(response.body.toString(),
              style: const TextStyle(fontSize: 14.0)),
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

// Auto-generated, check out https://javiercbk.github.io/json_to_dart/
class GithubTags {
  String? name;

  GithubTags({this.name});

  GithubTags.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    return data;
  }
}

class GithubReleaseLatest {
  String? name;
  String? body;

  GithubReleaseLatest({this.name, this.body});

  GithubReleaseLatest.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    body = json['body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['body'] = body;
    return data;
  }
}
