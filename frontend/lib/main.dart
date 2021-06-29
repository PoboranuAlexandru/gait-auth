import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:frontend/login_layout.dart';
import 'package:frontend/signup_layout.dart';
import 'package:frontend/homepage_layout.dart';

void main() {
  runApp(const Frontend());
}

class Frontend extends StatefulWidget {
  const Frontend({Key? key}) : super(key: key);

  @override
  _FrontendState createState() => _FrontendState();
}

class _FrontendState extends State<Frontend> {
  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const Login(),
        '/signup': (BuildContext context) => const Signup(),
        '/homepage': (BuildContext context) => const Homepage(
              token: 'aside',
            )
      },
      home: const Login(),
    );
  }
}
