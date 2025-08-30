import 'package:flutter/material.dart';

import '../config.dart';
import 'common.dart';

class DisplaySetting extends StatefulWidget {
  const DisplaySetting({super.key});

  @override
  State<DisplaySetting> createState() => _DisplaySettingState();
}

class _DisplaySettingState extends State<DisplaySetting> {
  @override
  Widget build(BuildContext context) {
    final ratioSlider = Slider(
      value: renderRatio,
      min: 0.01,
      onChanged: (value) {
        setState(() {
          renderRatio = value;
        });
      },
    );
    final detailSwitch = Switch(
      value: displayDetail,
      onChanged: (value) {
        setState(() {
          displayDetail = value;
        });
      },
    );
    final buttonSizeSlider = Slider(
      value: controlPaneButtonSize,
      min: 20,
      max: 150,
      onChanged: (value) {
        setState(() {
          controlPaneButtonSize = value;
        });
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnSpacing,
      children: [
        Text("Render Ratio: ${renderRatio.toStringAsFixed(2)}"),
        ratioSlider,
        row(Text("Display Detail: $displayDetail"), detailSwitch),
        Text(
          "Control Pane Button Size: ${controlPaneButtonSize.toStringAsFixed(2)}",
        ),
        buttonSizeSlider,
      ],
    );
  }
}
