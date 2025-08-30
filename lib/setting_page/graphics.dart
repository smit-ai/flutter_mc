import 'package:flutter/material.dart';

import '../config.dart';
import '../gpu/materials.dart';
import 'common.dart';

class GraphicsSetting extends StatefulWidget {
  const GraphicsSetting({super.key});

  @override
  State<GraphicsSetting> createState() => _GraphicsSettingState();
}

class _GraphicsSettingState extends State<GraphicsSetting> {
  void _stateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lightingModels = Wrap(
      spacing: 10,
      runSpacing: 5,
      children: [
        LightingSetButton(morning, _stateChanged),
        LightingSetButton(afternoon, _stateChanged),
        LightingSetButton(sunset, _stateChanged),
        LightingSetButton(moonlight, _stateChanged),
        LightingSetButton(rainy, _stateChanged),
        LightingSetButton(bloodMoon, _stateChanged),
        LightingSetButton(volcanic, _stateChanged),
        LightingSetButton(polarNight, _stateChanged),
        LightingSetButton(apocalypse, _stateChanged),
        LightingSetButton(radioactive, _stateChanged),
        LightingSetButton(nebula, _stateChanged),
        LightingSetButton(cyberpunk, _stateChanged),
        LightingSetButton(voidLight, _stateChanged),
        LightingSetButton(eldritch, _stateChanged),
        LightingSetButton(nether, _stateChanged),
        LightingSetButton(neutronStar, _stateChanged),
        LightingSetButton(blackHole, _stateChanged),
        LightingSetButton(biohazardOutbreak, _stateChanged),
      ],
    );
    final viewDistanceSlider = Slider(
      value: viewDistance.toDouble(),
      min: 0,
      max: 32,
      onChanged: (value) {
        setState(() {
          setViewDistance(value.round());
        });
      },
    );
    final fogSlider = RangeSlider(
      values: RangeValues(fogStart, fogEnd),
      min: 0,
      max: 2,
      onChanged: (value) {
        setState(() {
          fogStart = value.start;
          fogEnd = value.end;
          rebuildFogBufferFlag = true;
        });
      },
    );
    final fogHeightCompressionSlider = Slider(
      value: fogHeightCompression,
      min: 0,
      max: 1,
      onChanged: (value) {
        setState(() {
          fogHeightCompression = value;
          rebuildFogBufferFlag = true;
        });
      },
    );
    final sunRadiusSlider = Slider(
      value: sunRadius,
      min: 0,
      max: 300,
      onChanged: (value) {
        setState(() {
          sunRadius = value;
        });
      },
    );
    final sunBlurRangeSlider=RangeSlider(
      values: RangeValues(sunBlurStart,sunBlurEnd),
      min: 0,
      max: 2,
      onChanged: (value) {
        setState(() {
          sunBlurStart=value.start;
          sunBlurEnd=value.end;
        });
      },
    );
    final sunDistanceSlider=Slider(
      value: sunDistance,
      min: 0,
      max: 1000,
      onChanged: (value) {
        setState(() {
          sunDistance = value;
        });
      },
    );
    final fovSlider=Slider(
      value: fov,
      min: 20,
      max: 150,
      onChanged: (value) {
        setState(() {
          fov = value;
        });
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnSpacing,
      children: [
        Text("FOV (Vertical): ${fov.toStringAsFixed(2)}"),
        fovSlider,
        Text("lighting: ${selectedLighting.raw.name}"),
        lightingModels,
        Text("View Distance: $viewDistance"),
        viewDistanceSlider,
        Text(
          "Fog: ${fogStart.toStringAsFixed(2)} - ${fogEnd.toStringAsFixed(2)} of view distance",
        ),
        fogSlider,
        Text(
          "Fog Height Compression: ${fogHeightCompression.toStringAsFixed(2)} (make vertical fog more sparse)",
        ),
        fogHeightCompressionSlider,
        Text("Sun Radius: ${sunRadius.toStringAsFixed(2)}"),
        sunRadiusSlider,
        Text("Sun Blur Range: ${sunBlurStart.toStringAsFixed(2)} - ${sunBlurEnd.toStringAsFixed(2)}"),
        sunBlurRangeSlider,
        Text("Sun Distance: ${sunDistance.toStringAsFixed(2)}"),
        sunDistanceSlider,
      ],
    );
  }
}



class LightingSetButton extends StatelessWidget {
  final LightMaterialBuffered material;
  final VoidCallback stateChanged;

  const LightingSetButton(this.material, this.stateChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        useLighting(material);
        stateChanged();
      },
      child: Text(material.raw.name),
    );
  }
}