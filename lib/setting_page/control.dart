
import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/config.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  @override
  Widget build(BuildContext context) {
    final movingSpeedSlider=Slider(
      value: moveSpeed,
      min: 1,
      max: 30,
      onChanged: (value) {
        setState(() {
          moveSpeed = value;
        });
      },
    );
    final rotateSpeedSlider=Slider(
      value: rotateSpeed,
      min: 0,
      max: 0.06,
      onChanged: (value) {
        setState(() {
          rotateSpeed = value;
        });
      },
    );
    return Column(
      children: [
        Text("Moving Speed: ${moveSpeed.toStringAsFixed(2)}"),
        movingSpeedSlider,
        Text("Rotation Speed: ${rotateSpeed.toStringAsFixed(4)}"),
        rotateSpeedSlider,
      ],
    );
  }
}
