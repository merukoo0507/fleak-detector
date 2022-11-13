import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:fleak_detector/leak/detect_task.dart';
import 'package:fleak_detector/leak/vm_service_util.dart';
import 'package:fleak_detector/model/leak_node.dart';

import '../model/detector_event.dart';

class LeakDetector {
  static LeakDetector? _instance;
  static int maxRetainingPath = 300;
  factory LeakDetector() {
    _instance ??= LeakDetector._();
    return _instance!;
  }

  LeakDetector._();

  Future init({int? maxRetainingPath}) async {
    if (maxRetainingPath != null) {
      LeakDetector.maxRetainingPath = maxRetainingPath;
    }
    VmServiceUtils().getVmService();
  }

  final StreamController<LeakNode> _leakStreamController =
      StreamController.broadcast();
  final StreamController<DetectorEvent> _eventStreamController =
      StreamController.broadcast();
  Stream<LeakNode> get onLeakStream => _leakStreamController.stream;
  Stream<DetectorEvent> get onEventStream => _eventStreamController.stream;

  ///detected object
  final Map<String, Expando> _watchGroup = {};

  ///Queue to detect memory leaks, first in, first out
  final Queue<DetectorTask> _checkTaskQueue = Queue();
  DetectorTask? _currentTask;

  addLeakNode(LeakNode node) {
    _leakStreamController.sink.add(node);
  }

  addEvent(DetectorEvent event) {
    _eventStreamController.sink.add(event);
  }

  addWatchObject(Object obj, String group) {
    _eventStreamController
        .add(DetectorEvent(DetectorEventType.addObject, data: group));

    if (_checkType(obj)) {
      String key = group;
      Expando? expando = Expando('LeakChecker$key');
      expando[obj] = true;
      _watchGroup[key] = expando;
    }
  }

  void ensureReleaseAsync(String key, {int delay = 0}) {
    Expando? expando = _watchGroup[key];
    _watchGroup.remove(key);
    if (expando != null) {
      //延時檢測，有些state會在頁面退出之後延遲釋放，這並不表示就一定是內存洩漏。
      Timer(Duration(milliseconds: delay), () async {
        _checkTaskQueue.add(DetectorTask(
          expando!,
          sink: _eventStreamController.sink,
          onStart: () => _eventStreamController
              .add(DetectorEvent(DetectorEventType.check, data: key)),
          onResult: () {
            _currentTask = null;
            _checkStartTask();
          },
          onLeaked: (LeakNode? leakNode) {
            //notify listeners
            if (leakNode != null) {
              addLeakNode(leakNode);
            }
          },
        ));
        expando = null;
        _checkStartTask();
      });
    }
  }

  void _checkStartTask() {
    if (_checkTaskQueue.isNotEmpty) {
      _currentTask = _checkTaskQueue.removeFirst();
      _currentTask?.start();
    }
  }

  bool _checkType(object) {
    if ((object == null) ||
        (object is bool) ||
        (object is num) ||
        (object is String) ||
        (object is Pointer) ||
        (object is Struct)) {
      return false;
    }
    return true;
  }

  closeStream() {
    _leakStreamController.close();
    _eventStreamController.close();
  }
}
