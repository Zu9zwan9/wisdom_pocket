import 'package:flutter/material.dart';

import '../services/animation_settings.dart';
import '../services/feature_flags.dart';

class SettingsPage extends StatefulWidget {
  final AnimationSettings anim;
  final FeatureFlags flags;

  const SettingsPage({super.key, required this.anim, required this.flags});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AnimationSettings _anim;
  late FeatureFlags _flags;

  @override
  void initState() {
    super.initState();
    _anim = widget.anim;
    _flags = widget.flags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pocket Extraction Physics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _LabeledSlider(
            label: 'Stiffness',
            value: _anim.stiffness,
            min: 50,
            max: 500,
            onChanged: (v) => setState(() => _anim.stiffness = v),
            onChangeEnd: (_) => _anim.save(),
          ),
          _LabeledSlider(
            label: 'Damping',
            value: _anim.damping,
            min: 5,
            max: 40,
            onChanged: (v) => setState(() => _anim.damping = v),
            onChangeEnd: (_) => _anim.save(),
          ),
          _LabeledSlider(
            label: 'Max Pull',
            value: _anim.maxPull,
            min: 120,
            max: 360,
            onChanged: (v) => setState(() => _anim.maxPull = v),
            onChangeEnd: (_) => _anim.save(),
          ),
          const SizedBox(height: 16),
          Text(
            'Growth Experiments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            title: const Text('Share to unlock'),
            value: _flags.shareToUnlock,
            onChanged: (v) => setState(() {
              _flags.shareToUnlock = v;
              _flags.save();
            }),
          ),
          SwitchListTile(
            title: const Text('Referral flow'),
            value: _flags.referralFlow,
            onChanged: (v) => setState(() {
              _flags.referralFlow = v;
              _flags.save();
            }),
          ),
          SwitchListTile(
            title: const Text('Confetti on extract'),
            value: _flags.confettiOnExtract,
            onChanged: (v) => setState(() {
              _flags.confettiOnExtract = v;
              _flags.save();
            }),
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value.toStringAsFixed(0)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
