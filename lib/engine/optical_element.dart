import 'dart:math' as math;

import 'mueller_matrix.dart';

enum OpticalElementType {
  linearPolarizer,
  linearRetarder,
  opticalRotator,
}

class OpticalElement {
  const OpticalElement({
    required this.type,
    required this.name,
    this.enabled = true,
    this.angleDegrees = 0,
    this.retardanceDegrees = 90,
  });

  final OpticalElementType type;
  final String name;
  final bool enabled;
  final double angleDegrees;
  final double retardanceDegrees;

  OpticalElement copyWith({
    OpticalElementType? type,
    String? name,
    bool? enabled,
    double? angleDegrees,
    double? retardanceDegrees,
  }) =>
      OpticalElement(
        type: type ?? this.type,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        angleDegrees: angleDegrees ?? this.angleDegrees,
        retardanceDegrees: retardanceDegrees ?? this.retardanceDegrees,
      );

  String get typeLabel {
    switch (type) {
      case OpticalElementType.linearPolarizer:
        return 'Linear Polarizer';
      case OpticalElementType.linearRetarder:
        return 'Linear Retarder';
      case OpticalElementType.opticalRotator:
        return 'Optical Rotator';
    }
  }

  MuellerMatrix toMuellerMatrix() {
    final angleRad = _degToRad(angleDegrees);
    switch (type) {
      case OpticalElementType.linearPolarizer:
        return MuellerMatrix.linearPolarizer(angleRad);
      case OpticalElementType.linearRetarder:
        return MuellerMatrix.linearRetarder(angleRad, _degToRad(retardanceDegrees));
      case OpticalElementType.opticalRotator:
        return MuellerMatrix.opticalRotator(angleRad);
    }
  }

  static double _degToRad(double degrees) => degrees * math.pi / 180;
}
