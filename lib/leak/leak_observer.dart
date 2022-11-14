import 'package:fleak_detector/leak/leak_detector.dart';
import 'package:flutter/widgets.dart';

const defaultCheckDelay = 500;

class LeakObserver extends NavigatorObserver {
  static LeakObserver? _instance;
  factory LeakObserver({int delay = defaultCheckDelay}) {
    _instance ??= LeakObserver._();
    _instance!.checkLeakDelay = delay;
    return _instance!;
  }
  LeakObserver._();

  int checkLeakDelay = defaultCheckDelay;

  void add(Object object) {
    String key = _getObjectKey(object);
    LeakDetector().addWatchObject(object, key);
  }

  void remove(Object object) {
    String key = _getObjectKey(object);
    LeakDetector().ensureReleaseAsync(key, delay: checkLeakDelay);
  }

  ///generate key by [Object]
  String _getObjectKey(Object object) {
    final hasCode = object.hashCode.toString();
    String? key = object.toString();
    if (key.isEmpty) {
      key = object.hashCode.toString();
    } else {
      key = '$key($hasCode)';
    }
    return key;
  }

  ///Get the ‘Element’ of our custom page
  Element? _getElementByRoute(Route route) {
    Element? element;
    if (route is PageRoute) {
      //RepaintBoundary
      route.subtreeContext?.visitChildElements((child) {
        //Builder
        child.visitChildElements((child) {
          //Semantics
          child.visitChildElements((child) {
            //Page
            element = child;
          });
        });
      });
    }
    return element;
  }
}
