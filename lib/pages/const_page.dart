import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:flutter/material.dart';

class ConstPage extends StatefulWidget {
  const ConstPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ConstPageState();
  }
}

_TestObject? _object;

class _ConstPageState extends State<ConstPage> {
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
        title: const Text('ConstObject'),
      ),
      body: Center(
        child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(50),
              color: Colors.orange,
              child: const Text('pop'),
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
