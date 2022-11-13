import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const String _findLibrary = 'package:fleak_detector/leak/vm_service_util.dart';

class VmServiceUtils {
  static VmServiceUtils? _instance;

  bool _enable = false;
  VmService? _vmService;
  Uri? _observatoryUri;
  Isolate? _isolate;
  VM? _vm;

  factory VmServiceUtils() {
    _instance ??= VmServiceUtils._();
    return _instance!;
  }

  VmServiceUtils._() {
    _enable = true;
  }

  Future<VmService?> getVmService() async {
    if (_vmService == null) {
      final uri = await getObservatoryUri();
      if (uri != null) {
        Uri url = convertToWebSocketUrl(serviceProtocolUrl: uri);
        _vmService =
            await vmServiceConnectUri(url.toString()).catchError((error) {
          if (error is SocketException) {
            Fimber.e('vm_service connection refused, Try:');
            Fimber.e('run \'flutter run\' with --disable-dds to disable dds.');
          }
        });
      }
    }
    return _vmService;
  }

  Future<Uri?> getObservatoryUri() async {
    if (_enable) {
      ServiceProtocolInfo serviceProtocolInfo = await Service.getInfo();
      _observatoryUri = serviceProtocolInfo.serverUri;
    }
    return _observatoryUri;
  }

  Future<Isolate?> getIsolate() async {
    IsolateRef? ref;
    VM? vm = await getVM();
    if (vm == null) return null;
    if (_isolate == null) {
      _vm?.isolates?.forEach((isolate) {
        if (isolate.name == 'main') {
          ref = isolate;
        }
      });
      if (ref?.id != null) {
        final vms = await getVmService();
        _isolate = await vms?.getIsolate(ref!.id!);
      }
    }
    return _isolate;
  }

  Future<VM?> getVM() async {
    if (_vm == null) {
      final vms = await getVmService();
      _vm = await vms?.getVM();
    }
    return _vm;
  }

  Future startGCAsync() async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (isolate != null && isolate.id != null) {
      await _vmService!.getAllocationProfile(_isolate!.id!, gc: true);
    }
  }

  ///通过Object获取Instance
  Future<Instance?> getInstanceByObject(Expando expando) async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (vms != null || isolate?.id != null) {
      try {
        final expandoId = await getObjectId(expando);
        if (expandoId != null) {
          Obj expandoObj = await vms!.getObject(isolate!.id!, expandoId);
          final instance = Instance.parse(expandoObj.json);
          return instance;
        }

        await findLibrary(_findLibrary);
      } catch (e) {
        Fimber.d('getInstanceByObject error:$e');
      }
    }
    return null;
  }

  ///find a [Library] on [Isolate]
  Future<LibraryRef?> findLibrary(String uri) async {
    Isolate? isolate = await getIsolate();
    if (isolate != null) {
      final libraries = isolate.libraries;
      if (libraries != null) {
        for (int i = 0; i < libraries.length; i++) {
          var lib = libraries[i];
          if (lib.uri == uri) {
            return lib;
          }
        }
      }
    }
    return null;
  }

  ///get ObjectId in VM by Object
  Future<String?> getObjectId(dynamic obj) async {
    final library = await findLibrary(_findLibrary);
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (library == null ||
        library.id == null ||
        vms == null ||
        isolate == null ||
        isolate.id == null) return null;

    // 使用反射
    // 讓vm產生key, 將key返回後, 我們在全域變數中將_objCache[key]設為我們要觀察的物件,
    Response keyResponse =
        await vms.invoke(isolate.id!, library.id!, 'generateNewKey', []);
    final keyRef = InstanceRef.parse(keyResponse.json);
    String? key = keyRef?.valueAsString;

    if (key == null) return null;
    _objCache[key] = obj;

    try {
      // 再讓vm使用key的id取得key帶入keyToObj, 返回_objCache[key], 就可以得到expando的id
      Response valueResponse =
          await vms.invoke(isolate.id!, library.id!, "keyToObj", [keyRef!.id!]);
      final valueRef = InstanceRef.parse(valueResponse.json);
      return valueRef?.id;
    } catch (e) {
      Fimber.d('getObjectId $e');
    } finally {
      _objCache.remove(key);
    }
    return null;
  }

  Future<Obj?> getObjectInstanceById(String dataId) async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (vms == null || isolate == null || isolate.id == null) return null;
    return await vms.getObject(isolate.id!, dataId);
  }

  Future<RetainingPath?> getRetainingPaths(
      InstanceRef leakedInstance, int maxRetainingPath) async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (vms != null && isolate?.id != null && leakedInstance.id != null) {
      final retainingPath = await vms.getRetainingPath(
          isolate!.id!, leakedInstance.id!, maxRetainingPath);
      return retainingPath;
    }
    return null;
  }

  Future<T> getObjectOfType<T extends Obj?>(String objectId) async {
    var result = await getObjectInstanceById(objectId);
    return result as T;
  }
}

int _key = 0;

/// 顶级函数，必须常规方法，生成 key 用
String generateNewKey() {
  return "${++_key}";
}

Map<String, dynamic> _objCache = {};

/// 顶级函数，根据 key 返回指定对象
dynamic keyToObj(String key) {
  return _objCache[key];
}
