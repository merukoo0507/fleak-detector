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
    onResult?.call();
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
    var gcResult = await VmServiceUtils().startGCAsync();
    List<dynamic> weakPropertyKeys = await getWeakKeyRefs(expando!);

    //一定要释放引用
    expando = null;
    if (weakPropertyKeys.isEmpty) return null;
    sink?.add(DetectorEvent(DetectorEventType.startGC));
    gcResult = await VmServiceUtils().startGCAsync();

    List<LeakNode> leakNodes = [];
    LeakDetector().addEvent(DetectorEvent(DetectorEventType.startAnalyze));
    for (InstanceRef? instanceRef in weakPropertyKeys) {
      if (instanceRef == null || instanceRef.id == 'objects/null') {
        Fimber.d('checkLeak instanceRef = $instanceRef');
        break;
      }

      //找尋引用路徑s
      RetainingPath? retainingPath = await VmServiceUtils()
          .getRetainingPaths(instanceRef, LeakDetector.maxRetainingPath);
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
    LeakDetector().addEvent(DetectorEvent(DetectorEventType.endAnalyze));
    return leakNodes;
  }

  Future<List<InstanceRef>> getWeakKeyRefs(Expando expando) async {
    List<InstanceRef> instanceRefs = [];
    //原先使用弱引用，引用物件，但被WeakProperty包裹
    final weakPropertyRefs = await _getWeakProperty(expando);

    //基本所有的 API 返回的数据都是 ObjRef，当 ObjRef 里面的信息满足不了你的时候，再调用 getObject(,,,)来获取 Obj。
    //直接看weakPropertyRef是沒有propertyKey
    for (var i = 0; i < weakPropertyRefs.length; i++) {
      final weakPropertyRef = weakPropertyRefs[i];
      final weakPropertyId = weakPropertyRef.json?['id'];
      //根據id，找WeakProperty物件
      Obj? weakPropertyObj =
          await VmServiceUtils().getObjectOfType(weakPropertyId);

      if (weakPropertyObj != null) {
        final weakPropertyInstance = Instance.parse(weakPropertyObj.json);
        if (weakPropertyInstance!.propertyKey != null) {
          instanceRefs.add(weakPropertyInstance.propertyKey!);
        }
      }
    }

    return instanceRefs;
  }

  // 取得原先儲存在若引用的物件
  Future<List<InstanceRef>> _getWeakProperty(Expando expando) async {
    // 取得expando的id，再取得Expando
    String? expandoId = await VmServiceUtils().getObjectId(expando);
    if (expandoId == null) return [];
    Instance expandoObj = await VmServiceUtils().getObjectOfType(expandoId);
    List<InstanceRef> instanceRefs = [];
    for (var i = 0; i < expandoObj.fields!.length; i++) {
      var filed = expandoObj.fields![i];
      //在查詢裡面的data找到dataId，根據dataId找到data，(原先key对象是放到了_data数组内，用了一个_WeakProperty来包裹)
      if (filed.decl?.name == '_data') {
        String _dataId = filed.toJson()['value']['id'];
        Instance _data = await VmServiceUtils().getObjectOfType(_dataId);
        if (_data is Instance) {
          for (int j = 0; j < _data.elements!.length; j++) {
            var weakProperty = _data.elements![j];
            if (weakProperty is InstanceRef) {
              InstanceRef weakPropertyRef = weakProperty;
              //將data內，原先存取物件的reference取出
              instanceRefs.add(weakPropertyRef);
            }
          }
        }
      }
    }

    return instanceRefs;
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
