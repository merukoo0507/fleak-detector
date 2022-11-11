import 'dart:ui';

import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/detector_event.dart';
import 'package:fleak_detector/leak/vm_service_util.dart';
import 'package:vm_service/vm_service.dart';

import 'dart:async';

import 'leak_node.dart';

abstract class _Task<T> {
  void start() async {
    T? result;
    try {
      result = await run();
    } catch (e) {
      Fimber.d('_Task $e');
    } finally {
      done(result);
    }
  }

  Future<T?> run();

  void done(T? result);
}

class DetectorTask extends _Task {
  DetectorTask(this.expando,
      {this.sink, this.onStart, this.onResult, this.onLeaked});
  Expando expando;
  final VoidCallback? onStart;
  final Function()? onResult;
  final Function(LeakNode? leakInfo)? onLeaked;
  final StreamSink<DetectorEvent>? sink;

  Future<List<LeakNode>?> run({String? tag}) async {
    onStart?.call();
    await VmServiceUtils().startGCAsync(); //GC
    return await _analyzeLeakedPathAfterGC();
  }

  @override
  void done(result) {
    // TODO: implement done
  }

  ///after Full GC, check whether there is a leak,
  ///if there is an analysis of the leaked reference chain
  Future<List<LeakNode>?> _analyzeLeakedPathAfterGC() async {
    List<LeakNode>? leakNodes;
    if (expando == null) {
      Fimber.d('expando = null');
      return null;
    }
    //run GC,ensure Object should release
    sink?.add(DetectorEvent(DetectorEventType.startGC));
    List<dynamic> weakPropertyKeys = await _getWeakKeyRefs(expando!);

    sink?.add(DetectorEvent(DetectorEventType.endGc));
    return null;
  }

  ///List Item has id
  Future<List> _getWeakKeyRefs(Expando expando) async {
    Instance? instance = await VmServiceUtils().getInstanceByObject(expando);
    List<InstanceRef> instanceRefs = [];
    if (instance == null || instance.fields == null) return instanceRefs;
    for (int i = 0; i < instance.fields!.length; i++) {
      BoundField field = instance.fields![i];
      if (field.decl?.name == 'data') {
        String _dataId = field.toJson()['value']['id'];
        Obj? _data = await VmServiceUtils().getObject(_dataId);
      }
    }
  }
}
