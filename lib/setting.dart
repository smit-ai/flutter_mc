import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/about.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';

import 'gpu/materials.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final _pages = <Widget>[
    SingleChildScrollView(child: GraphicsSetting()),
    DisplaySetting(),
    About(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setting')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.photo),
                label: Text("Graphics"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.screenshot_monitor),
                label: Text("Display"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info),
                label: Text("About"),
              ),
            ],
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

final double columnSpacing = 10;

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

Widget row(Widget a, Widget b) {
  return Row(spacing: 10, children: [a, b]);
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
