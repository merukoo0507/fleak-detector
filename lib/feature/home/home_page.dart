import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../route/routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) => InkWell(
          onTap: (() {
            Navigator.of(context).pushNamed('/p${index + 1}');
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'p${index + 1}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        separatorBuilder: (context, index) {
          return Divider(
            height: 2,
            color: Colors.grey.withOpacity(0.25),
            indent: 16,
          );
        },
        itemCount: getRoutes().length,
      ),
    );
  }
}
