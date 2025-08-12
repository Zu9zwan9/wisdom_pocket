import 'package:flutter/material.dart';
import '../services/animation_settings.dart';
import '../services/feature_flags.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AnimationSettings animSettings;
  late FeatureFlags featureFlags;

  @override
  void initState() {
    super.initState();
    animSettings = AnimationSettings.instance;
    featureFlags = FeatureFlags.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAnimationSettings(),
            const SizedBox(height: 24),
            _buildFeatureFlags(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Animation Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              'Card Extraction Speed',
              animSettings.cardExtractionSpeed,
              0.1,
              2.0,
              (value) => setState(() {
                animSettings.cardExtractionSpeed = value;
                animSettings.save();
              }),
            ),
            _buildSlider(
              'Spring Back Speed',
              animSettings.springBackSpeed,
              0.1,
              3.0,
              (value) => setState(() {
                animSettings.springBackSpeed = value;
                animSettings.save();
              }),
            ),
            _buildSlider(
              'Pull Threshold',
              animSettings.pullThreshold,
              0.1,
              1.0,
              (value) => setState(() {
                animSettings.pullThreshold = value;
                animSettings.save();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlags() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSwitch(
              'Haptic Feedback',
              featureFlags.enableHapticFeedback,
              (value) => setState(() {
                featureFlags.enableHapticFeedback = value;
                featureFlags.save();
              }),
            ),
            _buildSwitch(
              'Sound Effects',
              featureFlags.enableSoundEffects,
              (value) => setState(() {
                featureFlags.enableSoundEffects = value;
                featureFlags.save();
              }),
            ),
            _buildSwitch(
              'Advanced Animations',
              featureFlags.enableAdvancedAnimations,
              (value) => setState(() {
                featureFlags.enableAdvancedAnimations = value;
                featureFlags.save();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
