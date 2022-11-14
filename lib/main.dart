import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:fleak_detector/model/leak_node.dart';
import 'package:fleak_detector/pages/home/home_page.dart';
import 'package:fleak_detector/pages/info_page.dart';
import 'package:fleak_detector/pages/page2.dart';
import 'package:fleak_detector/pages/second_page.dart';
import 'package:fleak_detector/pages/third_page.dart';
import 'package:fleak_detector/pages/watch_object.dart';
import 'package:flutter/material.dart';

import 'leak/leak_detector.dart';
import 'model/detector_event.dart';
import 'pages/first_page.dart';

void main() {
  Fimber.plantTree(DebugTree());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    LeakDetector().init(maxRetainingPath: 300);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        LeakObserver(),
      ],
      routes: {
        '/': (context) => const HomePage(title: 'fleak detector'),
        '/p1': (context) => NormalCase(),
        '/p2': (context) => WatchObjectPage(),
        '/p3': (context) => SecondPage(),
        '/p4': (context) => ThirdPage(),
        '/p100': (context) => InfoPage(),
      },
      initialRoute: '/',
    );
  }
}
