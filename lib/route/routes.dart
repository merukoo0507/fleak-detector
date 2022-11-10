import 'package:flutter/widgets.dart';

import '../feature/first_page.dart';
import '../feature/second_page.dart';
import '../feature/third_page.dart';

Map<String, WidgetBuilder> getRoutes() => {
      '/p1': (_) => const FirstPage(),
      '/p2': (_) => const SecondPage(),
      '/p3': (_) => const ThirdPage(),
    };
