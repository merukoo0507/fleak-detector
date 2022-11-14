import 'package:fleak_detector/leak/leak_detector.dart';
import 'package:fleak_detector/model/detector_event.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.title, Key? key}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    LeakDetector().onEventStream.listen((event) {
      print('$event');
      if (event.type == DetectorEventType.startAnalyze) {
        setState(() {
          _checking = true;
        });
      }
      if (event.type == DetectorEventType.endAnalyze) {
        setState(() {
          _checking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.adjust,
          color: _checking ? Colors.white : null,
        ),
        backgroundColor: _checking ? Colors.purple : null,
        onPressed: () {},
      ),
      body: Column(children: [
        PageItem(title: 'NormalCase', name: '/p1'),
        PageItem(title: 'WatchObjectPage', name: '/p2'),
        PageItem(title: 'P2', name: '/p3'),
        PageItem(title: 'P3', name: '/p3'),
        PageItem(title: 'Info', name: '/p100'),
      ]),
    );
  }
}

class PageItem extends StatelessWidget {
  PageItem({required this.name, this.title, this.onTap, Key? key})
      : super(key: key);
  String name;
  String? title;
  GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (() {
        Navigator.of(context).pushNamed(name);
      }),
      child: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        child: Text(
          title ?? name,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
