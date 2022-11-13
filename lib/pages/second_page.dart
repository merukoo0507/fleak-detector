import 'package:flutter/material.dart';

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        child: Center(
          child: TextButton(
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
        ),
      ),
    );
  }
}
