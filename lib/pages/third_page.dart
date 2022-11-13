import 'package:flutter/material.dart';

class ThirdPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.blue.shade100,
        child: InkWell(
          onTap: (() {
            Navigator.of(context).pop();
          }),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Back.'),
          ),
        ),
      ),
    );
  }
}
