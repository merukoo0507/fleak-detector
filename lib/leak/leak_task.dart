import 'leak_node.dart';

class LeakTask {
  LeakTask(this.expando);
  Expando expando;

  Future<List<LeakNode>?> start({String? tag}) async {}
}
