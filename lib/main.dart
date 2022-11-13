import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_observer.dart';
import 'package:fleak_detector/model/leak_node.dart';
import 'package:fleak_detector/pages/home/home_page.dart';
import 'package:fleak_detector/pages/second_page.dart';
import 'package:fleak_detector/pages/third_page.dart';
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
  bool _checking = false;
  String _leakInfo = '';

  @override
  void initState() {
    super.initState();
    LeakDetector().init(maxRetainingPath: 300);
    LeakDetector().onLeakStream.listen((LeakNode node) {
      //print to console
      Fimber.d('Node: ${node.toString()}');
      _leakInfo = node.toString();
      //show preview page
      // showLeakedInfoPage(navigatorKey.currentContext, info);
    });
    LeakDetector().onEventStream.listen((DetectorEvent event) {
      Fimber.d('{Event: ${event.type.toString()}');
      if (event.type == DetectorEventType.startAnalyze) {
        setState(() {
          _checking = true;
        });
      } else if (event.type == DetectorEventType.endAnalyze) {
        setState(() {
          _checking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        //used the LeakNavigatorObserver.
        LeakObserver(
            // shouldCheck: (route) {
            //You can customize which `route` can be detected
            //   return route.settings.name != null && route.settings.name != '/';
            // },
            ),
      ],
      home: const Scaffold(
        body: HomePage(title: 'fleak detector'),
      ),
    );
  }
}
