import 'dart:async';

import 'package:flutter/material.dart';

class ConstPage extends StatefulWidget {
  const ConstPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // SingleTon()._leakWidgets.add(this);
    return _ConstPage();
  }
}

class _ConstPage extends State<ConstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Const'),
      ),
      body: Center(
        child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(50),
              color: const Color.fromARGB(255, 98, 208, 245),
              child: const Text('pop'),
            )),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
