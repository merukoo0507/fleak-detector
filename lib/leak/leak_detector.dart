import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/detect_task.dart';
import 'package:fleak_detector/leak/vm_service_util.dart';
import 'package:fleak_detector/log/log_util.dart';
import 'package:fleak_detector/model/leak_node.dart';

import '../model/detector_event.dart';

class LeakDetector {
  static LeakDetector? _instance;
  static int maxRetainingPath = 300;
  factory LeakDetector() {
    if (_instance == null) {
      _instance = LeakDetector._();
      _instance!.init();
    }
    return _instance!;
  }

  LeakDetector._();

  List<LeakNode> listNode = [];

  Future init({int maxRetainingPath = 300}) async {
    LeakDetector.maxRetainingPath = maxRetainingPath;
    await VmServiceUtils().getVmService();

    LeakDetector().onLeakStream.listen((LeakNode node) {
      LogUtil.d('Node: ${node.toString()}');
      listNode.add(node);
    });
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

  addWatchObject(Object obj, String objKey) {
    _eventStreamController
        .add(DetectorEvent(DetectorEventType.addObject, data: objKey));

    if (_checkType(obj)) {
      String key = objKey;
      Expando? expando = Expando('LeakChecker/$key');
      expando[obj] = true;
      _watchGroup[key] = expando;
    }
  }

  void ensureReleaseAsync(String key, {int delay = 0}) {
    Expando? expando = _watchGroup[key];
    _watchGroup.remove(key);
    if (expando != null) {
      //延時檢測，有些state會在頁面退出之後延遲釋放，這並不表示就一定是內存洩漏。
      Timer(Duration(seconds: delay), () async {
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
    if (_checkTaskQueue.isNotEmpty && _currentTask == null) {
      _currentTask = _checkTaskQueue.removeFirst();

      Fimber.d("開始檢測 ${_currentTask?.expando}");
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
