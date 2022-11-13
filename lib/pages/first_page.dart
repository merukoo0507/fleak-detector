import 'dart:async';

import 'package:flutter/material.dart';

class FirstPage extends StatefulWidget {
  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  String currentTime = '';

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now().toIso8601String();
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now().toIso8601String();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(
          child: Column(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(this);
                },
                style: ButtonStyle(
                  side: MaterialStateProperty.resolveWith(
                    (states) => const BorderSide(width: 1, color: Colors.blue),
                  ),
                ),
                child: const Text('back'),
              ),
              Text(currentTime)
            ],
          ),
        ),
      ),
    );
  }
}
