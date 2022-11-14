import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:flutter/material.dart';

class WatchObjectPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WatchObjectState();
  }
}

_TestObject? _object;

class _WatchObjectState extends State<WatchObjectPage> {
  @override
  void initState() {
    super.initState();
    _object = _TestObject();
    LeakObserver().add(_object!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WatchObject'),
      ),
      body: Center(
        child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(50),
              color: Colors.orange,
              child: Text('pop'),
            )),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    LeakObserver().remove(_object!);
    super.dispose();
  }
}

class _TestObject {}
