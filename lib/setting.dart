import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/about.dart';
import 'package:flutter_gpu_demo/config.dart';
import 'package:flutter_gpu_demo/gpu/utils.dart';

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
    DisplaySetting(),
    GraphicsSetting(),
    About()
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
                icon: Icon(Icons.screenshot_monitor),
                label: Text("Display"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.photo),
                label: Text("Graphics"),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnSpacing,
      children: [
        Text("Render Ratio: ${renderRatio.toStringAsFixed(2)}"),
        Slider(
          value: renderRatio,
          min: 0.01,
          onChanged: (value) {
            setState(() {
              renderRatio = value;
            });
          },
        ),
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
  void _stateChanged(){
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: columnSpacing,
      children: [
        Text("lighting: ${selectedLighting.raw.name}"),
        Wrap(
          spacing: 20,
          runSpacing: 10, // 新增行间距属性
          children: [
            LightingSetButton(morning, _stateChanged),
            LightingSetButton(afternoon,_stateChanged),
            LightingSetButton(sunset,_stateChanged),
            LightingSetButton(moonlight, _stateChanged),
            LightingSetButton(rainy, _stateChanged),
            LightingSetButton(bloodMoon, _stateChanged),
            LightingSetButton(volcanic, _stateChanged),
            LightingSetButton(polarNight, _stateChanged),
            LightingSetButton(apocalypse, _stateChanged),
          ],
        )
      ],
    );
  }
}
class LightingSetButton extends StatelessWidget {
  final LightMaterialBuffered material;
  final VoidCallback stateChanged;
  const LightingSetButton(this.material,this.stateChanged,{super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: (){
      useLighting(material);
      stateChanged();
    }, child: Text(material.raw.name));
  }
}

