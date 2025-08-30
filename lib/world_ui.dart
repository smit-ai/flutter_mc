import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gpu_demo/gpu/world_data.dart';
import 'package:flutter_gpu_demo/ui.dart';
import 'package:flutter_gpu_demo/gpu/world.dart';


import 'config.dart';
import 'gpu/shaders.dart';
import 'gpu/utils.dart';

class World extends StatefulWidget {
  const World({super.key});

  @override
  State<World> createState() => _WorldState();
}

class _WorldState extends State<World> with TickerProviderStateMixin {
  double _moveSpeedByTime = 0;
  bool joyStickMoveState = false,
      upState = false,
      downState = false;
  Duration deltaTime = Duration.zero;
  Duration _lastTime = Duration.zero;
  late Ticker ticker;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    ticker = createTicker((elapsed) {
      deltaTime = elapsed - _lastTime;
      _lastTime = elapsed;
      calculateMoveSpeedByTime();
      if (joyStickMoveState) calculateJoystickMove();
      if (upState) calcUp();
      if (downState) calcDown();
      if (needBuild) {
        setState(() {
          needBuild = false;
        });
        notifier.notifyListeners();
      }
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void calculateMoveSpeedByTime() {
    _moveSpeedByTime = moveSpeed * deltaTime.inMilliseconds / 1000;
  }

  static const rad90 = pi / 2;


  void calcUp() {
    cameraPosition.y += _moveSpeedByTime;
    needBuild = true;
  }

  void calcDown() {
    cameraPosition.y -= _moveSpeedByTime;
    needBuild = true;
  }
  double joystickDx=0;
  double joystickDy=0;
  void calculateJoystickMove(){
    cameraPosition.x += _moveSpeedByTime * cos(horizonRotate + rad90 * 2)*joystickDy;
    cameraPosition.z -= _moveSpeedByTime * sin(horizonRotate + rad90 * 2)*joystickDy;
    cameraPosition.x += _moveSpeedByTime * cos(horizonRotate - rad90)*joystickDx;
    cameraPosition.z -= _moveSpeedByTime * sin(horizonRotate - rad90)*joystickDx;
    needBuild=true;
  }
  void onJoystickMove(double dx, double dy) {
    joystickDx=dx;
    joystickDy=dy;
    joyStickMoveState=true;
  }

  void onPointerDown(PointerDownEvent event) {
    lastPosition = event.position;
  }

  Offset lastPosition = Offset.zero;


  void onPointerMove(PointerMoveEvent event) {
    final dx = event.position.dx - lastPosition.dx;
    final dy = event.position.dy - lastPosition.dy;
    lastPosition = event.position;
    final newHorizonRotate = horizonRotate - dx * rotateSpeed;
    final newVerticalRotate = verticalRotate - dy * rotateSpeed;
    horizonRotate = newHorizonRotate;
    const rad90 = pi / 2 - 0.001;
    verticalRotate = min(max(-rad90, newVerticalRotate), rad90);
    needBuild = true;
  }

  bool needBuild = false;

  void markDirty() {
    needBuild = true;
  }

  WorldRender? render;

  void reloadRender(){
    setState(() {
      render=null;
    });
  }
  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    if (render == null) {
      render ??= WorldRender(
        cameraPosition,
        horizonRotate,
        verticalRotate,
        markDirty,
        mediaQueryData,
        renderRatio,
        notifier,
      );
    } else {
      render!.cameraPosition = cameraPosition;
      render!.horizonRotate = horizonRotate;
      render!.verticalRotate = verticalRotate;
    }

    final game = CustomPaint(size: mediaQueryData.size, painter: render);

    final controlPane = ControlPane(
      onUp: (state) {
        upState = state;
      },
      onDown: (state) {
        downState = state;
      },
      onJoystickMove: onJoystickMove,
      onJoyStickRelease: (){
        joyStickMoveState=false;
      },
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      buttonSize: controlPaneButtonSize,
    );
    final renderSize =
        mediaQueryData.size * mediaQueryData.devicePixelRatio * renderRatio;
    final controlMenu = ControlMenu(
      onReload: reloadRender,
    );
    final stack=<Widget>[
      game,
      controlPane,
      controlMenu,
    ];
    if(displayDetail){
      final topInfo=TopInfo(
        'Cam:${vecToString(cameraPosition)} HorRot:${horizonRotate.toStringAsFixed(1)} VertRot:${verticalRotate.toStringAsFixed(1)} '
            'Render:${renderSize.width.toInt()}x${renderSize.height.toInt()}',
      );
      stack.add(topInfo);
    }
    return Stack(
      children: stack,
    );
  }
}
