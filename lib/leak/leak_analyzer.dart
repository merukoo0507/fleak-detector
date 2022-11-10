import 'dart:async';

import 'package:fleak_detector/leak/vm_service_util.dart';

import 'detector_event.dart';
import 'leak_node.dart';

class LeakAnalyzer {
  static LeakAnalyzer? _instance;
  factory LeakAnalyzer() {
    _instance ??= LeakAnalyzer._();
    return _instance!;
  }

  LeakAnalyzer._();

  Future init() async {
    VmServiceUtils().getVmService();
  }

  final StreamController<LeakNode> _leakStreamController =
      StreamController.broadcast();

  final StreamController<DetectorEvent> _eventStreamController =
      StreamController.broadcast();

  Stream<LeakNode> get onLeakStream => _leakStreamController.stream;
  Stream<DetectorEvent> get onEventStream => _eventStreamController.stream;

  addLeakNode(LeakNode node) {
    _leakStreamController.sink.add(node);
  }

  closeStream() {
    _leakStreamController.close();
  }
}
