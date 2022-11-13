import 'dart:ui';

import 'package:fimber/fimber.dart';
import 'package:fleak_detector/leak/leak_detector.dart';
import 'package:fleak_detector/leak/vm_service_util.dart';
import 'package:fleak_detector/model/leak_node.dart';
import 'package:vm_service/vm_service.dart';

import 'dart:async';

import '../model/detector_event.dart';
import '../model/pares_leak.dart';

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
  Expando? expando;
  final VoidCallback? onStart;
  final Function()? onResult;
  final Function(LeakNode? leakNode)? onLeaked;
  final StreamSink<DetectorEvent>? sink;

  Future<List<LeakNode>?> run({String? tag}) async {
    onStart?.call();
    return await _analyzeLeakedPathAfterGC();
  }

  @override
  void done(result) {
    // TODO: implement done
  }

  ///after Full GC, check whether there is a leak,
  ///if there is an analysis of the leaked reference chain
  Future<List<LeakNode>?> _analyzeLeakedPathAfterGC() async {
    if (expando == null) {
      Fimber.d('expando = null');
      return null;
    }
    //run GC,ensure Object should release
    //GC
    sink?.add(DetectorEvent(DetectorEventType.startGC));
    await VmServiceUtils().startGCAsync();
    List<dynamic> weakPropertyList =
        await _getExpandoWeakPropertyList(expando!);
    //一定要释放引用
    expando = null;
    if (weakPropertyList.isEmpty) return null;

    // await VmServiceUtils().startGCAsync();
    sink?.add(DetectorEvent(DetectorEventType.endGc));

    List<LeakNode> leakNodes = [];
    sink?.add(DetectorEvent(DetectorEventType.startAnalyze));
    try {
      for (var weakProperty in weakPropertyList) {
        if (weakProperty == null) continue;
        final leakedInstance = await _getWeakPropertyKey(weakProperty.id!);
        if (leakedInstance == null) continue;
        final retainingPath = await VmServiceUtils()
            .getRetainingPaths(leakedInstance, LeakDetector.maxRetainingPath);
        if (retainingPath?.elements == null) continue;
        LeakNode? _leakInfoHead;
        LeakNode? pre;
        bool isBreak = false;
        for (var i = 0; i < retainingPath!.elements!.length; i++) {
          RetainingObject p = retainingPath.elements![i];

          LeakNode current = LeakNode();
          current.parentField = p.parentField;
          bool skip = await parsers[p.value!.runtimeType]
                  ?.paresRefSkip(p.value!, p.parentField, current) ??
              true;

          if (skip) {
            isBreak = true;
            break;
          }

          if (_leakInfoHead == null) {
            _leakInfoHead = current;
            pre = _leakInfoHead;
          } else {
            pre?.next = current;
            pre = current;
          }
        }

        if (isBreak) {
          break;
        }

        if (_leakInfoHead != null) {
          leakNodes.add(_leakInfoHead);
          onLeaked?.call(_leakInfoHead);
        }
      }
    } catch (e) {
      print('Error - find retaining path: $e');
    }
    sink?.add(DetectorEvent(DetectorEventType.endAnalyze));
    return leakNodes;
  }

  ///List Item has id
  Future<List> _getExpandoWeakPropertyList(Expando expando) async {
    Instance? instance = await VmServiceUtils().getInstanceByObject(expando);
    if (instance == null || instance.fields == null) return [];
    for (int i = 0; i < instance.fields!.length; i++) {
      BoundField field = instance.fields![i];
      if (field.decl?.name == '_data') {
        String _dataId = field.toJson()['value']['id'];
        final dataObj =
            await VmServiceUtils().getObjectInstanceById(_dataId) as Instance;
        if (dataObj.json != null) {
          Instance? weakListInstance = Instance.parse(dataObj.json!);
          if (weakListInstance != null) {
            return weakListInstance.elements ?? [];
          }
        }
      }
    }
    return [];
  }

  Future<InstanceRef?> _getWeakPropertyKey(String id) async {
    final weakPropertyObj = await VmServiceUtils().getObjectInstanceById(id);
    if (weakPropertyObj != null) {
      final weakPropertyInstance = Instance.parse(weakPropertyObj.json);
      return weakPropertyInstance?.propertyKey;
    }
    return null;
  }
}
