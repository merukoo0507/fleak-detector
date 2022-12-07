import 'dart:async';

import 'package:flutter/material.dart';

final List _states = [];

// class SingleTon {
//   final List _leakWidgets = [];
//   static SingleTon _singleTon = SingleTon._();

//   factory SingleTon() => _singleTon;

//   SingleTon._();
// }

class GlobalPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // SingleTon()._leakWidgets.add(this);
    return _GlobalPage();
  }
}

class _GlobalPage extends State<GlobalPage> {
  @override
  void initState() {
    super.initState();
    _states.add(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Global Access'),
      ),
      body: Center(
        child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(50),
              color: Color.fromARGB(255, 98, 208, 245),
              child: Text('pop'),
            )),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
