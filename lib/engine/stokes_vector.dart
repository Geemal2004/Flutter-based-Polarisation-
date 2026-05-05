import 'dart:math' as math;

class StokesVector {
  const StokesVector._(this.s0, this.s1, this.s2, this.s3);

  final double s0;
  final double s1;
  final double s2;
  final double s3;

  factory StokesVector.custom(
    double s0,
    double s1,
    double s2,
    double s3,
  ) =>
      StokesVector._(s0, s1, s2, s3);

  factory StokesVector.horizontalLinear() => const StokesVector._(1, 1, 0, 0);
  factory StokesVector.verticalLinear() => const StokesVector._(1, -1, 0, 0);
  factory StokesVector.rightCircular() => const StokesVector._(1, 0, 0, 1);
  factory StokesVector.leftCircular() => const StokesVector._(1, 0, 0, -1);
  factory StokesVector.unpolarized() => const StokesVector._(1, 0, 0, 0);

  double get intensity => s0;

  double get degreeOfPolarization {
    if (s0 == 0) {
      return 0;
    }
    final magnitude = math.sqrt(s1 * s1 + s2 * s2 + s3 * s3);
    return magnitude / s0;
  }

  double get azimuth => 0.5 * math.atan2(s2, s1);

  double get ellipticity {
    final dop = degreeOfPolarization;
    if (dop == 0 || s0 == 0) {
      return 0;
    }
    final ratio = (s3 / (s0 * dop)).clamp(-1.0, 1.0);
    return 0.5 * math.asin(ratio);
  }

  bool get isValid {
    final magnitude = math.sqrt(s1 * s1 + s2 * s2 + s3 * s3);
    return s0 >= magnitude;
  }

  double get poincareX => s0 == 0 ? 0 : s1 / s0;
  double get poincareY => s0 == 0 ? 0 : s2 / s0;
  double get poincareZ => s0 == 0 ? 0 : s3 / s0;

  @Deprecated('Use poincareX instead.')
  double get poincare_x => poincareX;
  @Deprecated('Use poincareY instead.')
  double get poincare_y => poincareY;
  @Deprecated('Use poincareZ instead.')
  double get poincare_z => poincareZ;

  List<double> toList() => [s0, s1, s2, s3];

  @override
  String toString() => 'StokesVector([$s0, $s1, $s2, $s3])';
}
