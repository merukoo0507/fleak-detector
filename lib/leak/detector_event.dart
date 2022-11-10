class DetectorEvent {
  final DetectorEventType type;
  final dynamic data;

  @override
  String toString() {
    return '$type, $data';
  }

  DetectorEvent(this.type, {this.data});
}

enum DetectorEventType {
  addObject, //add a object
  check,
  startGC,
  endGc,
  startAnalyze,
  endAnalyze,
}
