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
  VmService? _vmService;
  Uri? _observatoryUri;
  Isolate? _isolate;
  VM? _vm;

  factory VmServiceUtils() {
    _instance ??= VmServiceUtils._();
    return _instance!;
  }

  VmServiceUtils._();

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
    ServiceProtocolInfo serviceProtocolInfo = await Service.getInfo();
    _observatoryUri = serviceProtocolInfo.serverUri;
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

  Future<AllocationProfile?> startGCAsync() async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (vms != null && isolate != null && isolate.id != null) {
      return await vms.getAllocationProfile(_isolate!.id!, gc: true);
    }
    return null;
  }

  ///??????Object??????Instance
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

    // ????????????
    // ???vm??????key, ???key?????????, ???????????????????????????_objCache[key]??????????????????????????????,
    Response keyResponse =
        await vms.invoke(isolate.id!, library.id!, 'generateNewKey', []);
    final keyRef = InstanceRef.parse(keyResponse.json);
    String? key = keyRef?.valueAsString;

    if (key == null) return null;
    _objCache[key] = obj;

    try {
      // ??????vm??????key???id??????key??????keyToObj, ??????_objCache[key], ???????????????expando???id
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

  Future<Obj?> getObjectInstanceById(String objectId) async {
    final vms = await getVmService();
    final isolate = await getIsolate();
    if (vms == null || isolate == null || isolate.id == null) return null;
    return await vms.getObject(isolate.id!, objectId);
  }
}

int _key = 0;

/// ?????????????????????????????????????????? key ???
String generateNewKey() {
  return "${++_key}";
}

Map<String, dynamic> _objCache = {};

/// ????????????????????? key ??????????????????
dynamic keyToObj(String key) {
  return _objCache[key];
}
