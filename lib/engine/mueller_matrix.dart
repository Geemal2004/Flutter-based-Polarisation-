import 'dart:math' as math;

import 'stokes_vector.dart';

class MuellerMatrix {
  MuellerMatrix._(List<double> values) : _values = List<double>.unmodifiable(values) {
    if (values.length != 16) {
      throw ArgumentError('MuellerMatrix requires 16 values.');
    }
  }

  final List<double> _values;

  factory MuellerMatrix.identity() => MuellerMatrix._(<double>[
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  factory MuellerMatrix.fromRows(List<List<double>> rows) {
    if (rows.length != 4 || rows.any((row) => row.length != 4)) {
      throw ArgumentError('MuellerMatrix requires a 4x4 list.');
    }
    return MuellerMatrix._(rows.expand((row) => row).toList());
  }

  factory MuellerMatrix.linearPolarizer(double angleRad) {
    final cos2 = math.cos(2 * angleRad);
    final sin2 = math.sin(2 * angleRad);
    final cos2Sq = cos2 * cos2;
    final sin2Sq = sin2 * sin2;
    final cosSin = cos2 * sin2;

    return MuellerMatrix._(<double>[
      0.5, 0.5 * cos2, 0.5 * sin2, 0,
      0.5 * cos2, 0.5 * cos2Sq, 0.5 * cosSin, 0,
      0.5 * sin2, 0.5 * cosSin, 0.5 * sin2Sq, 0,
      0, 0, 0, 0,
    ]);
  }

  factory MuellerMatrix.linearRetarder(double angleRad, double retardanceRad) {
    final retarder = MuellerMatrix._(<double>[
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, math.cos(retardanceRad), math.sin(retardanceRad),
      0, 0, -math.sin(retardanceRad), math.cos(retardanceRad),
    ]);
    final rotation = MuellerMatrix._stokesRotation(2 * angleRad);
    final rotationBack = MuellerMatrix._stokesRotation(-2 * angleRad);
    return rotationBack.multiply(retarder).multiply(rotation);
  }

  factory MuellerMatrix.opticalRotator(double angleRad) =>
      MuellerMatrix._stokesRotation(2 * angleRad);

  static MuellerMatrix _stokesRotation(double angleRad) {
    final c = math.cos(angleRad);
    final s = math.sin(angleRad);
    return MuellerMatrix._(<double>[
      1, 0, 0, 0,
      0, c, s, 0,
      0, -s, c, 0,
      0, 0, 0, 1,
    ]);
  }

  double entry(int row, int col) => _values[row * 4 + col];

  MuellerMatrix multiply(MuellerMatrix other) {
    final result = List<double>.filled(16, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += entry(row, k) * other.entry(k, col);
        }
        result[row * 4 + col] = sum;
      }
    }
    return MuellerMatrix._(result);
  }

  StokesVector applyTo(StokesVector vector) {
    final s0 = entry(0, 0) * vector.s0 +
        entry(0, 1) * vector.s1 +
        entry(0, 2) * vector.s2 +
        entry(0, 3) * vector.s3;
    final s1 = entry(1, 0) * vector.s0 +
        entry(1, 1) * vector.s1 +
        entry(1, 2) * vector.s2 +
        entry(1, 3) * vector.s3;
    final s2 = entry(2, 0) * vector.s0 +
        entry(2, 1) * vector.s1 +
        entry(2, 2) * vector.s2 +
        entry(2, 3) * vector.s3;
    final s3 = entry(3, 0) * vector.s0 +
        entry(3, 1) * vector.s1 +
        entry(3, 2) * vector.s2 +
        entry(3, 3) * vector.s3;
    return StokesVector.custom(s0, s1, s2, s3);
  }

  List<double> toRowMajorList() => List<double>.unmodifiable(_values);
}
