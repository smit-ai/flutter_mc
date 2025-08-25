import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:flutter_gpu_demo/ui.dart';
import 'package:flutter_gpu_demo/gpu/world.dart';
import 'package:vector_math/vector_math_64.dart';

import 'gpu/utils.dart';

class World extends StatefulWidget {
  const World({super.key});

  @override
  State<World> createState() => _WorldState();
}

class _WorldState extends State<World> with TickerProviderStateMixin {
  Vector3 cameraPosition = Vector3(2, levelHeight*1.2, 2);
  double horizonRotate = 2.4;
  double verticalRotate = -0.6;
  double moveSpeed=4;
  double _moveSpeedByTime = 0;
  double renderRatio=0.5;
  bool forwardState=false,
      backState=false,
      leftState=false,
      rightState=false,
      upState=false,
      downState=false;
  Duration deltaTime=Duration.zero;
  Duration _lastTime=Duration.zero;
  late Ticker ticker;
  @override
  void initState() {
    super.initState();
    ticker=createTicker((elapsed) {
      if(needBuild){
        setState(() {
          needBuild=false;
        });
      }
      deltaTime=elapsed-_lastTime;
      _lastTime=elapsed;
      calculateMoveSpeedByTime();
      if(forwardState)onForward();
      if(backState)onBack();
      if(leftState)onLeft();
      if(rightState)onRight();
      if(upState)onUp();
      if(downState)onDown();
    });
    ticker.start();

  }
  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }
  void calculateMoveSpeedByTime() {
    _moveSpeedByTime=moveSpeed*deltaTime.inMilliseconds/1000;
  }
  static const rad90=pi/2;
  void onForward() {
    setState(() {
      cameraPosition.x += _moveSpeedByTime*cos(horizonRotate);
      cameraPosition.z -= _moveSpeedByTime*sin(horizonRotate);
    });
  }

  void onBack() {
    setState(() {
      cameraPosition.x += _moveSpeedByTime*cos(horizonRotate+rad90*2);
      cameraPosition.z -= _moveSpeedByTime*sin(horizonRotate+rad90*2);
    });
  }

  void onLeft() {
    setState(() {
      cameraPosition.x += _moveSpeedByTime*cos(horizonRotate+rad90);
      cameraPosition.z -= _moveSpeedByTime*sin(horizonRotate+rad90);
    });
  }

  void onRight() {
    setState(() {
      cameraPosition.x += _moveSpeedByTime*cos(horizonRotate-rad90);
      cameraPosition.z -= _moveSpeedByTime*sin(horizonRotate-rad90);
    });
  }

  void onUp() {
    setState(() {
      cameraPosition.y += _moveSpeedByTime;
    });
  }

  void onDown() {
    setState(() {
      cameraPosition.y -= _moveSpeedByTime;
    });
  }

  void onPointerDown(PointerDownEvent event) {
    lastPosition=event.position;
  }
  Offset lastPosition = Offset.zero;
  final double rotateSpeed = 0.01;
  void onPointerMove(PointerMoveEvent event) {
    final dx=event.position.dx-lastPosition.dx;
    final dy=event.position.dy-lastPosition.dy;
    setState(() {
      lastPosition=event.position;
      final newHorizonRotate = horizonRotate - dx*rotateSpeed;
      final newVerticalRotate = verticalRotate - dy*rotateSpeed;
      horizonRotate = newHorizonRotate;
      const rad90=pi/2-0.001;
      verticalRotate = min(max(-rad90,newVerticalRotate),rad90);
    });
  }
  bool needBuild=false;
  void markDirty(){
    needBuild=true;
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    final ratio=mediaQueryData.devicePixelRatio;
    final painter=WorldRender(cameraPosition, horizonRotate, verticalRotate,markDirty,mediaQueryData,renderRatio);
    final game =CustomPaint(
      size: mediaQueryData.size,
      painter: painter,
    );




    final controlPane = ControlPane(
      onForward: (state){forwardState=state;},
      onBack: (state){backState=state;},
      onLeft: (state){leftState=state;},
      onRight: (state){rightState=state;},
      onUp: (state){upState=state;},
      onDown: (state){downState=state;},
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
    );
    final renderSize=mediaQueryData.size*mediaQueryData.devicePixelRatio*renderRatio;
    return Stack(children: [
      game,
      controlPane,
      TopInfo('Cam:${vecToString(cameraPosition)} HorRot:${horizonRotate.toStringAsFixed(1)} VertRot:${verticalRotate.toStringAsFixed(1)} '
          'Render:${renderSize.width.toInt()}x${renderSize.height.toInt()}'),
    ]);
  }
}

