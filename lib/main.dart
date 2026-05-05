import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'engine/optical_element.dart';
import 'engine/stokes_vector.dart';

void main() {
  runApp(const OptiCalcApp());
}

class OptiCalcApp extends StatelessWidget {
  const OptiCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptiCalc Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OptiCalcHomePage(),
    );
  }
}

class OptiCalcHomePage extends StatefulWidget {
  const OptiCalcHomePage({super.key});

  @override
  State<OptiCalcHomePage> createState() => _OptiCalcHomePageState();
}

class _OptiCalcHomePageState extends State<OptiCalcHomePage> {
  StokesPreset _preset = StokesPreset.horizontalLinear;
  final TextEditingController _s0Controller = TextEditingController(text: '1');
  final TextEditingController _s1Controller = TextEditingController(text: '0');
  final TextEditingController _s2Controller = TextEditingController(text: '0');
  final TextEditingController _s3Controller = TextEditingController(text: '0');

  late List<OpticalElement> _elements = <OpticalElement>[
    const OpticalElement(
      type: OpticalElementType.linearPolarizer,
      name: 'Input Polarizer',
      angleDegrees: 0,
    ),
    const OpticalElement(
      type: OpticalElementType.linearRetarder,
      name: 'Wave Plate',
      angleDegrees: 0,
      retardanceDegrees: 90,
    ),
    const OpticalElement(
      type: OpticalElementType.opticalRotator,
      name: 'Optical Rotator',
      angleDegrees: 0,
    ),
  ];

  @override
  void dispose() {
    _s0Controller.dispose();
    _s1Controller.dispose();
    _s2Controller.dispose();
    _s3Controller.dispose();
    super.dispose();
  }

  StokesVector get _inputVector {
    switch (_preset) {
      case StokesPreset.horizontalLinear:
        return StokesVector.horizontalLinear();
      case StokesPreset.verticalLinear:
        return StokesVector.verticalLinear();
      case StokesPreset.rightCircular:
        return StokesVector.rightCircular();
      case StokesPreset.leftCircular:
        return StokesVector.leftCircular();
      case StokesPreset.unpolarized:
        return StokesVector.unpolarized();
      case StokesPreset.custom:
        return StokesVector.custom(
          _parseController(_s0Controller, fallback: 1),
          _parseController(_s1Controller),
          _parseController(_s2Controller),
          _parseController(_s3Controller),
        );
    }
  }

  StokesVector get _outputVector {
    var vector = _inputVector;
    for (final element in _elements) {
      if (!element.enabled) {
        continue;
      }
      vector = element.toMuellerMatrix().applyTo(vector);
    }
    return vector;
  }

  @override
  Widget build(BuildContext context) {
    final output = _outputVector;
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiCalc Mobile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputSection(),
              const SizedBox(height: 16),
              _buildElementChainSection(),
              const SizedBox(height: 16),
              _buildOutputSection(output),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Stokes Vector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StokesPreset>(
              value: _preset,
              decoration: const InputDecoration(labelText: 'Preset'),
              items: StokesPreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(preset.label),
                    ),
                  )
                  .toList(),
              onChanged: (preset) {
                if (preset == null) {
                  return;
                }
                setState(() {
                  _preset = preset;
                });
              },
            ),
            if (_preset == StokesPreset.custom) ...[
              const SizedBox(height: 12),
              _buildVectorField('S0', _s0Controller),
              _buildVectorField('S1', _s1Controller),
              _buildVectorField('S2', _s2Controller),
              _buildVectorField('S3', _s3Controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVectorField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildElementChainSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optical Element Chain',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._elements.asMap().entries.map(
                  (entry) => _buildElementCard(entry.key, entry.value),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementCard(int index, OpticalElement element) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(element.name),
              subtitle: Text(element.typeLabel),
              value: element.enabled,
              onChanged: (value) {
                setState(() {
                  _elements[index] = element.copyWith(enabled: value);
                });
              },
            ),
            const SizedBox(height: 8),
            _buildAngleSlider(
              label: 'Angle',
              value: element.angleDegrees,
              max: 180,
              onChanged: (value) {
                setState(() {
                  _elements[index] = element.copyWith(angleDegrees: value);
                });
              },
            ),
            if (element.type == OpticalElementType.linearRetarder)
              _buildAngleSlider(
                label: 'Retardance',
                value: element.retardanceDegrees,
                max: 360,
                onChanged: (value) {
                  setState(() {
                    _elements[index] = element.copyWith(retardanceDegrees: value);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleSlider({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}°'),
        Slider(
          value: value,
          min: 0,
          max: max,
          divisions: max.round(),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildOutputSection(StokesVector output) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Output Stokes Vector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildVectorRow('S0', output.s0),
            _buildVectorRow('S1', output.s1),
            _buildVectorRow('S2', output.s2),
            _buildVectorRow('S3', output.s3),
            const Divider(height: 24),
            _buildVectorRow('Intensity', output.intensity),
            _buildVectorRow(
              'Degree of Polarization',
              output.degreeOfPolarization,
            ),
            _buildVectorRow(
              'Azimuth (deg)',
              _radToDeg(output.azimuth),
            ),
            _buildVectorRow(
              'Ellipticity (deg)',
              _radToDeg(output.ellipticity),
            ),
            _buildVectorRow('Valid', output.isValid ? 1 : 0),
            const Divider(height: 24),
            _buildVectorRow('Poincaré X', output.poincare_x),
            _buildVectorRow('Poincaré Y', output.poincare_y),
            _buildVectorRow('Poincaré Z', output.poincare_z),
          ],
        ),
      ),
    );
  }

  Widget _buildVectorRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(4)),
        ],
      ),
    );
  }

  double _parseController(TextEditingController controller, {double fallback = 0}) {
    return double.tryParse(controller.text) ?? fallback;
  }

  double _radToDeg(double radians) => radians * 180 / math.pi;
}

enum StokesPreset {
  horizontalLinear,
  verticalLinear,
  rightCircular,
  leftCircular,
  unpolarized,
  custom,
}

extension StokesPresetLabel on StokesPreset {
  String get label {
    switch (this) {
      case StokesPreset.horizontalLinear:
        return 'Horizontal Linear';
      case StokesPreset.verticalLinear:
        return 'Vertical Linear';
      case StokesPreset.rightCircular:
        return 'Right Circular';
      case StokesPreset.leftCircular:
        return 'Left Circular';
      case StokesPreset.unpolarized:
        return 'Unpolarized';
      case StokesPreset.custom:
        return 'Custom';
    }
  }
}
