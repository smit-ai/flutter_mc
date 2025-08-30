import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/setting_page/about.dart';
import 'package:flutter_gpu_demo/setting_page/index.dart';

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
    ControlPage(),
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
                icon: Icon(Icons.control_camera),
                label: Text("Control"),
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



