import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:fleak_detector/pages/home/home_page.dart';
import 'package:fleak_detector/pages/info_page.dart';
import 'package:fleak_detector/pages/normal_page.dart';
import 'package:fleak_detector/pages/performace_page.dart';
import 'package:flutter/material.dart';
import 'pages/const_page.dart';
import 'pages/leak_page.dart';

void main() {
  Fimber.plantTree(DebugTree());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        LeakObserver(
            shouldAdd: ((route) =>
                route.settings.name != '/' && route.settings.name != '/pInfo')),
      ],
      routes: {
        '/': (context) => const HomePage(title: 'fleak detector'),
        '/p1': (context) => NormalPage(),
        '/p2': (context) => LeakPage(),
        '/p3': (context) => PerformancePage(),
        '/pInfo': (context) => InfoPage(),
      },
      initialRoute: '/',
    );
  }
}
