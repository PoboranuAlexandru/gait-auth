import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/credential_validation.dart';
import 'package:frontend/homepage_layout.dart';
import 'package:frontend/constants.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final CredentialValidator _credentialValidator = CredentialValidator();
  String? _error;

  Future<bool?> _signup(String email, String password) async {
    final http.Response response = await http.post(
      Uri(
        scheme: 'https',
        host: backendUrl,
        port: backendPort,
        pathSegments: <String>['auth', 'register'],
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
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
      _error = response.body;
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
                child: Builder(
                  builder: (BuildContext context) => Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                        ),
                        validator: (String? value) => _credentialValidator.username(value),
                      ),
                      TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                        ),
                        validator: (String? value) => _credentialValidator.password(value),
                      ),
                      TextFormField(
                        obscureText: true,
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          hintText: 'Confirm Password',
                        ),
                        validator: (String? value) =>
                            _credentialValidator.confirmPassword(value, _passwordController.text),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (Form.of(context)!.validate()) {
                              // Process data.
                              _signup(_emailController.text, _passwordController.text);
                            }
                          },
                          child: const Text('Sign up'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
