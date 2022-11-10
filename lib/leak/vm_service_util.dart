import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:fimber/fimber.dart';
import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

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

  Future startGC() async {
    if (_isolate != null && _isolate?.id != null && _vmService != null) {
      await _vmService!.getAllocationProfile(_isolate!.id!, gc: true);
    }
  }

  Future<Isolate?> getIsolate() async {
    IsolateRef? ref;
    if (_isolate == null) {
      _vm?.isolates?.forEach((isolate) {
        if (isolate.name == 'main') {
          ref = isolate;
        }
      });
      if (ref?.id != null) {
        _isolate = await _vmService?.getIsolate(ref!.id!);
      }
    }
    return _isolate;
  }

  Future<VM?> getVM() async {
    if (_vm == null) {
      final vmservice = _vmService ?? await getVmService();
      _vm = await vmservice?.getVM();
    }
    return _vm;
  }
}
