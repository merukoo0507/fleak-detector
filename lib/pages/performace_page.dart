import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

final List leakObjects = [];

class MemoryLeakObject {
  MemoryLeakObject(this.text);
  String text;
}

class PerformancePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PerformancePage();
}

class _PerformancePage extends State<PerformancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performace'),
      ),
      body: Column(
        children: [
          GestureDetector(
              onTap: () {
                while (leakObjects.length < 1000000) {
                  leakObjects
                      .add(MemoryLeakObject('Count: ${leakObjects.length}'));
                }
                print('leakObjects: ${leakObjects.length}');
              },
              child: Container(
                padding: EdgeInsets.all(20),
                color: Color.fromARGB(255, 23, 69, 220),
                child: Text(
                  'Create 1 000 000 leaks.',
                  style: TextStyle(color: Colors.white),
                ),
              )),
          GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.all(50),
                color: Color.fromARGB(255, 98, 208, 245),
                child: Text('pop'),
              )),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
