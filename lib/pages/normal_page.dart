import 'package:flutter/material.dart';

class NormalPage extends StatefulWidget {
  NormalPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NormalPageState();
  }
}

class _NormalPageState extends State<NormalPage> {
  Count count = Count();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NormalPage'),
      ),
      body: Column(
        children: [
          Text(
            '${count.value}',
            style: const TextStyle(fontSize: 16),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              setState(() {
                count.value = count.value + 1;
              });
            },
          ),
          GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(50),
                color: Color.fromARGB(255, 98, 208, 245),
                child: const Text('pop'),
              )),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Count {
  int value = 0;
}
