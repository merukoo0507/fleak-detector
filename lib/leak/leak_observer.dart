import 'package:fimber/fimber.dart';
import 'package:flutter/widgets.dart';

import 'leak_task.dart';

const defaultCheckDelay = 5;
typedef ShouldAddedRoute = bool Function(Route rout);

class LeakObserver extends NavigatorObserver {
  LeakObserver({this.shouldCheck, this.checkLeakDelay = defaultCheckDelay});

  final ShouldAddedRoute? shouldCheck;
  final int checkLeakDelay;

  @override
  void didPop(Route route, Route? previousRoute) {
    _remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      _add(newRoute);
    }
    if (oldRoute != null) {
      _remove(oldRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  Map<String, Expando> _widgetMap = {};
  Map<String, Expando> _stateMap = {};

  void _add(Route route) {
    Element? element = _getElementByRoute(route);
    if (element != null) {
      route.didPush().then((value) {
        Fimber.d('加入檢測: ${_getRouteKey(route)}');
        Expando expando = Expando('${element.widget}');
        expando[element.widget] = true;
        _widgetMap[_getRouteKey(route)] = expando;

        if (element is StatefulElement) {
          Expando expandoState = Expando('${element.state}');
          expando[element.state] = true;
          _stateMap[_getRouteKey(route)] = expandoState;
        }
      });
    }
  }

  void _remove(Route route) {
    Element? element = _getElementByRoute(route);
    Expando? expando = _widgetMap.remove(_getRouteKey(route));
    if (element != null && expando != null) {
      Future.delayed(Duration(seconds: checkLeakDelay), () {
        LeakTask(expando).start(tag: 'Widget leaks');
      });
    }
  }

  ///Get the ‘Element’ of our custom page
  Element? _getElementByRoute(Route route) {
    Element? element;
    if (route is ModalRoute && (shouldCheck == null || shouldCheck!(route))) {
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

  ///generate key by [Route]
  String _getRouteKey(Route route) {
    final hasCode = route.hashCode.toString();
    String? key = route.settings.name;
    if (key == null || key.isEmpty) {
      key = route.hashCode.toString();
    } else {
      key = '$key($hasCode)';
    }
    return key;
  }
}
