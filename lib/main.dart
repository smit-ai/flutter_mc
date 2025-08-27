import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:flutter_gpu_demo/ui.dart';
import 'package:flutter_gpu_demo/gpu/world.dart';
import 'package:flutter_gpu_demo/world_ui.dart';
import 'package:statsfl/statsfl.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'config.dart';

void main() async{
  if(!kIsWeb){
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
  }
  hideNotificationBar();
  await ensureInitialize();
  // var a=Chunk.calculateDirectionalVec(0,0,[-0.5,0.466,-0.94,-0.73]);
  runApp(fpsMonitor());
}
Widget fpsMonitor(){
  return StatsFl(
      isEnabled: true, //Toggle on/off
      width: 150, //Set size
      height: 20, //
      // maxFps: 190, // Support custom FPS target (default is 60)
      showText: true, // Hide text label
      sampleTime: .5, //Interval between fps calculations, in seconds.
      totalTime: 5, //Total length of timeline, in seconds.
      align: Alignment.bottomRight, //Alignment of statsbox
      child: MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GPU 3D',
      home: Scaffold(body: World()),
    );
  }
}

