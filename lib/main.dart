import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:fleak_detector/pages/home/home_page.dart';
import 'package:fleak_detector/pages/info_page.dart';
import 'package:fleak_detector/pages/normal_page.dart';
import 'package:fleak_detector/pages/const_page.dart';
import 'package:flutter/material.dart';
import 'leak/leak_detector.dart';

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
        '/p1': (context) => const NormalPage(),
        '/p2': (context) => const ConstPage(),
        '/p100': (context) => const InfoPage(),
      },
      initialRoute: '/',
    );
  }
}
