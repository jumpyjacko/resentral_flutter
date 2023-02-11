import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(25.0, 40.0, 25.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About reSentral',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10.0),
            const Text(
              '\'reSentral\' is an open-source project authored by an Australian high school student who was fed up by Sentral\'s lacklustre design and poor support for the mobile users.\n\nWhile this app is not undoubtedly the better version of \'Sentral\', it is a different take on what it could\'ve been in the mobile space.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 30.0),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  child: Text(
                    'Github',
                    style: TextStyle(
                        fontSize: 16.0,
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () => launchUrl(Uri.parse(
                      'https://github.com/JumpyJacko/resentral_flutter')),
                )
              ],
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0.0,
        title: Text('About',
            style:
                TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.onBackground,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
