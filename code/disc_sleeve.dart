import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Une pochette d'où sort un vinyle qui tourne.
/// `active` déclenche la sortie (true) ou la rentrée (false) du disque.
class DiscSleeve extends StatefulWidget {
  final bool active;
  final List<Color> sleeveColors;
  final Color labelColor;
  final IconData icon;

  const DiscSleeve({
    super.key,
    required this.active,
    required this.sleeveColors,
    required this.labelColor,
    required this.icon,
  });

  @override
  State<DiscSleeve> createState() => _DiscSleeveState();
}

class _DiscSleeveState extends State<DiscSleeve> with TickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final Animation<double> _out =
      CurvedAnimation(parent: _slide, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _slide.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant DiscSleeve old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _slide.forward() : _slide.reverse();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sleeveSize = 210.0;
    return SizedBox(
      width: 330,
      height: 250,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slide, _spin]),
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Disque (derrière la pochette)
              Positioned(
                left: 15 + _out.value * 105,
                child: Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(sleeveSize - 10, sleeveSize - 10),
                    painter: _VinylPainter(widget.labelColor),
                  ),
                ),
              ),
              // Pochette (devant)
              Positioned(
                left: 15,
                child: Container(
                  width: sleeveSize,
                  height: sleeveSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: widget.sleeveColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 84, color: Colors.white.withAlpha(215)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final Color label;
  _VinylPainter(this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0B0B0B));

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withAlpha(22);
    for (double g = r * 0.42; g < r - 4; g += 7) {
      canvas.drawCircle(c, g, groove);
    }

    // Reflet pour mieux voir la rotation
    final shine = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withAlpha(40),
          Colors.transparent,
          Colors.transparent,
          Colors.white.withAlpha(40),
          Colors.transparent,
        ],
        stops: const [0, 0.1, 0.2, 0.5, 0.6, 0.7],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, shine);

    canvas.drawCircle(c, r * 0.3, Paint()..color = label);
    canvas.drawCircle(c, r * 0.05, Paint()..color = const Color(0xFF0B0B0B));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) => old.label != label;
}
