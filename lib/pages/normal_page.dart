import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:flutter/material.dart';

class NormalPage extends StatefulWidget {
  const NormalPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _NormalPageState();
  }
}

class _NormalPageState extends State<NormalPage> {
  Count count = Count();

  @override
  void initState() {
    LeakObserver().add(count);
    super.initState();
  }

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
                color: Colors.red,
                child: const Text('pop'),
              )),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    LeakObserver().remove(count);
    super.dispose();
  }
}

class Count {
  int value = 0;
}
