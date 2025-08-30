import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ButtonLike extends StatelessWidget {
  final Widget child;
  const ButtonLike({super.key,required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: child,),
    );
  }
}


class ControlPane extends StatelessWidget {
  final double buttonSize;
  final void Function(double,double) onJoystickMove;
  final void Function() onJoyStickRelease;
  final void Function(bool) onUp;
  final void Function(bool) onDown;
  final void Function(PointerDownEvent) onPointerDown;
  final void Function(PointerMoveEvent) onPointerMove;

  const ControlPane({
    super.key,
    this.buttonSize = 70,
    required this.onUp,
    required this.onDown,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onJoystickMove,
    required this.onJoyStickRelease,
  });

  Widget generateButton(void Function(bool) onPressed, IconData icon) {
    final btn=ButtonLike(child: Icon(icon,size: 30,));
    return GestureDetector(
      onPanDown: (event) => onPressed(true),
      onPanUpdate: (event)=> onPressed(true),
      onPanEnd: (event) => onPressed(false),
      onPanCancel: () => onPressed(false),
      child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: btn
      ),
    );
  }

  static final buttonShape = ButtonStyle(
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static const double gridSpaceBetween = 5;

  @override
  Widget build(BuildContext context) {
    final leftPaneSize = buttonSize * 3 + gridSpaceBetween * 2;
    final up = generateButton(onUp, Icons.arrow_drop_up_sharp);
    final down = generateButton(onDown, Icons.arrow_drop_down_sharp);
    final leftPane = Joystick(
        radius: leftPaneSize/2,
        callback: onJoystickMove,
        onRelease: onJoyStickRelease
    );
    final rightPane = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: gridSpaceBetween,
      children: [up, down],
    );

    final component = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: leftPaneSize,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: leftPaneSize,
                  height: leftPaneSize,
                  child: leftPane,
                ),
                rightPane,
              ],
            ),
          ),
        ),
      ],
    );
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: onPointerDown,
          onPointerMove: onPointerMove,
          child: component,
        ),
        component,
      ],
    );
  }
}

class TopInfo extends StatelessWidget {
  final String text;

  const TopInfo(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Text(text,textAlign: TextAlign.center,)],
    );
  }
}

class PointerMoveIndicator extends StatefulWidget {
  const PointerMoveIndicator({super.key});

  @override
  State<PointerMoveIndicator> createState() => _PointerMoveIndicatorState();
}

class _PointerMoveIndicatorState extends State<PointerMoveIndicator> {
  PointerEvent? _event;

  @override
  Widget build(BuildContext context) {
    return Listener(
      child: Container(
        alignment: Alignment.center,
        color: Colors.blue,
        width: 300.0,
        height: 150.0,
        child: Text(
          '${_event?.localPosition ?? ''}',
          style: TextStyle(color: Colors.white),
        ),
      ),
      onPointerDown: (PointerDownEvent event) => setState(() => _event = event),
      onPointerMove: (PointerMoveEvent event) => setState(() => _event = event),
      onPointerUp: (PointerUpEvent event) => setState(() => _event = event),
    );
  }
}

void hideNotificationBar(){
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
}

class ControlMenu extends StatelessWidget {
  final VoidCallback onReload;
  const ControlMenu({super.key,required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onReload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class McButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;

  const McButton({super.key, this.onPressed, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}




class Joystick extends StatefulWidget {
  final double radius;
  final Function(double dx, double dy) callback;
  final VoidCallback onRelease;

  const Joystick({super.key, required this.radius, required this.callback,required this.onRelease});

  @override
  createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _stickPosition = Offset.zero;
  late Offset _center;

  @override
  void initState() {
    super.initState();
    _center = Offset(widget.radius, widget.radius);
  }
  final double _stickRadius = 35;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // 计算摇杆的位置
          Offset newOffset = details.localPosition;
          double dx = newOffset.dx - _center.dx;
          double dy = newOffset.dy - _center.dy;

          // 限制摇杆在半径范围内移动
          double distance = sqrt(dx * dx + dy * dy);
          if (distance > widget.radius) {
            double scale = widget.radius / distance;
            dx = dx * scale;
            dy = dy * scale;
          }

          _stickPosition = Offset(dx, dy);
          double normalizedDx = dx / widget.radius;
          double normalizedDy = dy / widget.radius;
          // 回调
          widget.callback(normalizedDx, normalizedDy);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _stickPosition = Offset.zero;
          widget.callback(0.0, 0.0); // 当手指离开时，回调零值
        });
        widget.onRelease();
      },
      child: Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40), // 半透明圆形区域
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Positioned(
              left: _center.dx + _stickPosition.dx - _stickRadius/2,
              top: _center.dy + _stickPosition.dy - _stickRadius/2,
              child: Container(
                width: _stickRadius,
                height: _stickRadius,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80), // 半透明小圆
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}