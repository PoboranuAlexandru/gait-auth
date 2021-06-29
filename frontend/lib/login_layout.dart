import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/signup_layout.dart';
import 'package:frontend/homepage_layout.dart';
import 'package:frontend/constants.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  Future<bool?> _login(String email, String password) async {
    final http.Response response = await http.post(
      Uri(
        scheme: 'https',
        host: backendUrl,
        port: backendPort,
        pathSegments: <String>['auth', 'login'],
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final String token = body['token'] as String;

      Navigator.pushAndRemoveUntil<void>(
        context,
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => Homepage(token: token),
          transitionDuration: Duration.zero,
        ),
        (Route<dynamic> route) => false,
      );

      return true;
    }

    setState(() {
      _error = 'Email/Password incorrect';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo App'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              Form(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                      ),
                    ),
                    TextFormField(
                      obscureText: true,
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate will return true if the form is valid, or false if
                          // the form is invalid.
                          _login(_emailController.text, _passwordController.text);
                          _emailController.clear();
                          _passwordController.clear();
                        },
                        child: const Text('Log In'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    PageRouteBuilder<void>(
                      pageBuilder: (_, __, ___) => const Signup(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                child: const Text('Sign up'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
