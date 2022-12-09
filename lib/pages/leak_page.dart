import 'package:flutter/material.dart';

final List _states = [];

// class SingleTon {
//   final List _leakWidgets = [];
//   static SingleTon _singleTon = SingleTon._();

//   factory SingleTon() => _singleTon;

//   SingleTon._();
// }

class LeakPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // SingleTon()._leakWidgets.add(this);
    return _LeakPageState();
  }
}

class _LeakPageState extends State<LeakPage> {
  @override
  void initState() {
    super.initState();
    _states.add(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leak'),
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
    );
  }
}
