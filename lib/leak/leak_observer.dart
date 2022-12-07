import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const defaultCheckDelay = 2;

typedef ShouldAddedRoute = bool Function(Route route);

class LeakObserver extends NavigatorObserver {
  static LeakObserver? _instance;
  factory LeakObserver(
      {int delay = defaultCheckDelay, ShouldAddedRoute? shouldAdd}) {
    _instance ??= LeakObserver._();
    _instance!.checkLeakDelay = delay;
    _instance!.shouldAdd = shouldAdd;
    return _instance!;
  }
  LeakObserver._();

  int checkLeakDelay = defaultCheckDelay;
  ShouldAddedRoute? shouldAdd;

  @override
  void didPop(Route route, Route? previousRoute) {
    if (kDebugMode) {
      _removeRoute(route);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (kDebugMode) {
      _addRoute(route);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (kDebugMode) {
      _removeRoute(route);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (kDebugMode) {
      if (newRoute != null) {
        _addRoute(newRoute);
      }
      if (oldRoute != null) {
        _removeRoute(oldRoute);
      }
    }
  }

  void _add(Object object) {
    String key = _generateKey(object);
    LeakDetector().addWatchObject(object, key);
  }

  void _remove(Object object) {
    String key = _generateKey(object);
    LeakDetector().ensureReleaseAsync(key, delay: checkLeakDelay);
  }

  void _addRoute(Route route) {
    route.didPush().then((value) {
      Element? element = _getElementByRoute(route);
      if (element == null) return;
      String key = _generateKey(element.widget);
      LeakDetector().addWatchObject(element.widget, key);
      if (element is StatefulElement) {
        key = _generateKey(element.state);
        LeakDetector().addWatchObject(element.state, key);
      }
    });
  }

  void _removeRoute(Route route) {
    Element? element = _getElementByRoute(route);
    if (element == null) return;
    String key = _generateKey(element.widget);
    LeakDetector().ensureReleaseAsync(key, delay: checkLeakDelay);
    if (element is StatefulElement) {
      key = _generateKey(element.state);
      LeakDetector().ensureReleaseAsync(key, delay: checkLeakDelay);
    }
  }

  String _generateRouteKey(Route route) {
    return '${route.settings.name}(${route.hashCode})';
  }

  ///generate key by [Object]
  String _generateKey(Object object) {
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
    if (route is PageRoute && (shouldAdd?.call(route) ?? true)) {
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
