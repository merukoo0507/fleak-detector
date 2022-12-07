import 'package:fleak_detector/leak/leak_detector.dart';
import 'package:fleak_detector/model/leak_node.dart';
import 'package:flutter/material.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  List<LeakNode> nodes = [];

  @override
  void initState() {
    nodes = LeakDetector().listNode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
              onPressed: () {
                LeakDetector().listNode = [];
                setState(() {
                  nodes = LeakDetector().listNode;
                });
              },
              child: const Text('Clear')),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: ((context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nodes[index].toString()),
                    // children: [
                    //   InfoItem('gc root field - > ${nodes[index].name}',
                    //       InfoType.FIELD),
                    //   InfoItem(
                    //       'code - > ${nodes[index].codeInfo?.toString() ?? ''}',
                    //       InfoType.CODE),
                    //   InfoItem(
                    //       'uri - > ${nodes[index].codeInfo?.uri}', InfoType.URI),
                  ],
                );
              }),
              itemCount: nodes.length,
              separatorBuilder: (context, index) => Container(
                color: Colors.grey,
                height: 2,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  InfoItem(this.info, this.type, {Key? key}) : super(key: key) {
    switch (type) {
      case InfoType.FIELD:
      case InfoType.CODE:
        color = const Color.fromARGB(255, 42, 92, 44);
        break;
      case InfoType.URI:
        color = const Color.fromARGB(255, 22, 99, 162);
        break;
    }
  }
  String info;
  InfoType type;
  late Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        info,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}

enum InfoType { FIELD, CODE, URI }
