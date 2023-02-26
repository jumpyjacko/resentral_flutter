import 'package:flutter/material.dart';

class AnnouncementsChildPage extends StatelessWidget {
  const AnnouncementsChildPage(
      {super.key,
      required String title,
      required String name,
      required String body})
      : _title = title,
        _name = name,
        _body = body;

  final String _title;
  final String _name;
  final String _body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              Text(
                _title,
                style: const TextStyle(fontSize: 24.0),
              ),
              Text(
                _name,
                style: TextStyle(
                  fontSize: 12.0,
                  color:
                      Theme.of(context).colorScheme.onBackground.withAlpha(175),
                ),
              ),
              const SizedBox(height: 10.0),
              Text(
                _body,
                style: const TextStyle(fontSize: 15.0),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0.0,
        title: Text('Announcement',
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
