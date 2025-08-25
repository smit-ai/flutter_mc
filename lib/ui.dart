import 'package:flutter/material.dart';

class ButtonLike extends StatelessWidget {
  final Widget child;
  const ButtonLike({super.key,required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: child,),
    );
  }
}


class ControlPane extends StatelessWidget {
  final double buttonSize;
  final void Function(bool) onForward;
  final void Function(bool) onBack;
  final void Function(bool) onLeft;
  final void Function(bool) onRight;
  final void Function(bool) onUp;
  final void Function(bool) onDown;
  final void Function(PointerDownEvent) onPointerDown;
  final void Function(PointerMoveEvent) onPointerMove;

  const ControlPane({
    super.key,
    this.buttonSize = 60,
    required this.onForward,
    required this.onBack,
    required this.onLeft,
    required this.onRight,
    required this.onUp,
    required this.onDown,
    required this.onPointerDown,
    required this.onPointerMove,
  });

  Widget generateButton(void Function(bool) onPressed, IconData icon) {
    final btn=ButtonLike(child: Icon(icon,size: 30,));
    return GestureDetector(
      onTapDown: (event) => onPressed(true),
      onTapUp: (event) => onPressed(false),
      onTapCancel: () => onPressed(false),
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

    final empty = SizedBox(width: buttonSize, height: buttonSize);
    final forward = generateButton(onForward, Icons.arrow_drop_up_sharp);
    final back = generateButton(onBack, Icons.arrow_drop_down_sharp);
    final left = generateButton(onLeft, Icons.arrow_left);
    final right = generateButton(onRight, Icons.arrow_right);
    final up = generateButton(onUp, Icons.arrow_drop_up_sharp);
    final down = generateButton(onDown, Icons.arrow_drop_down_sharp);
    final leftPane = GridView(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 横轴三个子元素
        childAspectRatio: 1.0, // 宽高比为1时，子元素的长宽一样
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        empty,
        forward,
        empty,
        left,
        empty,
        right,
        empty,
        back,
        empty,
      ],
    );
    final rightPane = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      spacing: gridSpaceBetween,
      children: [up, down],
    );
    final leftPaneSize = buttonSize * 3 + gridSpaceBetween * 2;
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
      children: [Text(text)],
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
