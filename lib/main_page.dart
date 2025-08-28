import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gpu_demo/setting.dart';
import 'package:flutter_gpu_demo/ui.dart';
import 'package:flutter_gpu_demo/world_ui.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  void _startGame() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Material(child: World())));
  }

  void _gotoSetting() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingPage()));
  }

  @override
  Widget build(BuildContext context) {
    final mainText = Text(
      'FlutterCraft',
      textScaler: TextScaler.linear(3),
      style: TextStyle(fontWeight: FontWeight.bold),
    );
    final bottom=Align(
      alignment: Alignment.bottomCenter,
      child:Text("Made by 57U.  https://github.com/57UU/flutter_mc"),
    );
    final content = Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 30,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: mainText,
          ),
          McButton(onPressed: _startGame, child: Text('Start Game')),
          McButton(onPressed: _gotoSetting, child: Text('Setting')),
        ],
      ),
    );
    return Stack(
      children: [
        content,
        bottom
      ],
    );
  }
}

