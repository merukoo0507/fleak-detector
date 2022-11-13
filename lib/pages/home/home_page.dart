import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.title, Key? key}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  bool _checking = false;

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
        backgroundColor: _checking ? Colors.red : null,
        onPressed: () {},
      ),
      body: Container(
        child: ListView.separated(
          itemBuilder: (context, index) => InkWell(
            onTap: (() {
              final name = '/p${index + 1}';
              Navigator.of(context).pushNamed(name);
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
          itemCount: 3,
        ),
      ),
    );
  }
}
