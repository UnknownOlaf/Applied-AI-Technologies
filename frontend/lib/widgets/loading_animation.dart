import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingAnimation({
    Key? key,
    this.color = Colors.green,
    this.size = 40.0,
  }) : super(key: key);

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: List.generate(
                3,
                (index) {
                  final delay = index * 0.33;
                  final rotation = (_controller.value + delay) % 1.0;
                  
                  return Transform.scale(
                    scale: 1.0 - (index * 0.15),
                    child: Transform.rotate(
                      angle: rotation * 2 * 3.14,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.color.withOpacity(1.0 - (index * 0.3)),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
