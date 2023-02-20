import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:io';

import 'package:resentral/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  late AnimationController controller;
  late Animation loginOpenAnimation;

  void _saveLogin(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('password', password);
  }

  void _setSchoolWebsite(String website) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('website', website);
  }

  void _resetLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    prefs.remove('password');
  }

  Future<String> getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username')! + prefs.getString('password')!;
  }

  @override
  void initState() {
    super.initState();
    _resetLogin();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    loginOpenAnimation = Tween<double>(begin: 0.0, end: 450.0).animate(
        CurvedAnimation(
            parent: controller, curve: Curves.easeInOutCubicEmphasized));
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    usernameController.dispose();
    passwordController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    RotateAnimatedText(
                      'Welcome to ',
                      textStyle: const TextStyle(
                        fontSize: 25.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      rotateOut: false,
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(''),
                    TyperAnimatedText(
                      're',
                      textStyle: TextStyle(
                        fontSize: 25.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  totalRepeatCount: 1,
                  onFinished: () {
                    controller.forward();
                  },
                  pause: const Duration(seconds: 1, milliseconds: 500),
                ),
                AnimatedTextKit(
                  animatedTexts: [
                    RotateAnimatedText(
                      'Sentral',
                      textStyle: const TextStyle(
                        fontSize: 25.0,
                      ),
                      duration: const Duration(milliseconds: 500),
                      rotateOut: false,
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
              ],
            ),
            SizedBox(
              height: loginOpenAnimation.value,
              child: Column(
                children: [
                  const SizedBox(height: 50.0),
                  const Text('Login', style: TextStyle(fontSize: 16.0)),
                  const SizedBox(height: 10.0),
                  Text('Use your sentral login details',
                      style: TextStyle(
                          fontSize: 12.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withAlpha(150))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
                    child: TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Username',
                          hintText: ''),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Password',
                        hintText: '',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
                    child: TextField(
                      controller: websiteController,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: 'Website/Sentral URL',
                        hintText: '',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (usernameController.text != '' &&
                          passwordController.text != '' &&
                          websiteController.text != '') {
                        _saveLogin(
                          usernameController.text,
                          passwordController.text,
                        );
                        _setSchoolWebsite(websiteController.text);
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => const HomePage()));
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
