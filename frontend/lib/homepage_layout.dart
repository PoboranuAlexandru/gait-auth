import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:frontend/login_layout.dart';
import 'package:frontend/constants.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key, required this.token}) : super(key: key);
  final String token;

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _isLoading = false;
  bool _firstTime = true;
  bool? _isGranted;
  String? _error;
  bool _isDisableRequest = false;

  Future<void> _disableButtonTimeout() async {
    await Future<dynamic>.delayed(const Duration(seconds: 10));
    setState(() {
      _isDisableRequest = false;
    });
  }

  Future<void> _requestAccess() async {
    final http.Response response = await http.post(
      Uri(
        scheme: 'https',
        host: backendUrl,
        port: backendPort,
        pathSegments: <String>['auth', 'request_prediction'],
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'user_token': widget.token,
      }),
    );

    setState(() {
      _isLoading = false;
      if (response.statusCode != 200 && response.statusCode != 403) {
        _error = response.body;
        _isDisableRequest = false;
      } else {
        if (response.statusCode == 200) {
          _isGranted = true;
        } else if (response.statusCode == 403) {
          _isGranted = false;
        }
        _firstTime = false;
        _disableButtonTimeout();
      }
    });
  }

  Future<void> _logout() async {
    http.post(
      Uri(
        scheme: 'https',
        host: backendUrl,
        port: backendPort,
        pathSegments: <String>['auth', 'logout'],
      ),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'user_token': widget.token,
      }),
    );
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
                  textAlign: TextAlign.center,
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              if (_isGranted == true && _isLoading == false)
                const Text(
                  'Access granted',
                  textScaleFactor: 2.0,
                  style: TextStyle(color: Colors.green),
                ),
              if (_isGranted == false && _isLoading == false)
                const Text(
                  'Access denied',
                  textScaleFactor: 2.0,
                  style: TextStyle(color: Colors.red),
                ),
              if (_firstTime)
                Column(
                  children: <Widget>[
                    const Text(
                      'Insert this token in the Fitbit App:',
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        widget.token,
                        textScaleFactor: 2.0,
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _isDisableRequest
                      ? null
                      : () {
                          setState(() {
                            _error = null;
                            _isGranted = null;
                            _isLoading = true;
                            _isDisableRequest = true;
                          });
                          _requestAccess();
                        },
                  child: _isDisableRequest ? const Text('Hold on') : const Text('Request access'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _logout();
                        Navigator.pushAndRemoveUntil<void>(
                          context,
                          PageRouteBuilder<void>(
                            pageBuilder: (_, __, ___) => const Login(),
                            transitionDuration: Duration.zero,
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                child: const Text('Log out'),
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
