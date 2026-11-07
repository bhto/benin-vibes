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
  late final Animation<double> _out = CurvedAnimation(
    parent: _slide,
    curve: Curves.easeOutBack,
  );

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
    const sleeveSize = 220.0;
    final glow = widget.sleeveColors.first;
    return SizedBox(
      width: 350,
      height: 262,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slide, _spin]),
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Disque (derrière la pochette)
              Positioned(
                left: 15 + _out.value * 112,
                child: Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(sleeveSize - 12, sleeveSize - 12),
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
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: widget.sleeveColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(140),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: glow.withAlpha(60),
                        blurRadius: 50,
                        spreadRadius: -8,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Reflet haut-gauche
                      Positioned(
                        top: -70,
                        left: -50,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withAlpha(38),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(26),
                            border: Border.all(
                              color: Colors.white.withAlpha(46),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 48,
                            color: Colors.white.withAlpha(235),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        bottom: 16,
                        child: Text(
                          'BENIN VIBES',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.6,
                            color: Colors.white.withAlpha(170),
                          ),
                        ),
                      ),
                    ],
                  ),
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

    final discPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A), Color(0xFF050505)],
        stops: [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, discPaint);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withAlpha(26),
    );

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withAlpha(20);
    for (double g = r * 0.42; g < r - 5; g += 6.5) {
      canvas.drawCircle(c, g, groove);
    }

    // Reflet pour mieux voir la rotation
    final shine = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withAlpha(36),
          Colors.transparent,
          Colors.transparent,
          Colors.white.withAlpha(26),
          Colors.transparent,
        ],
        stops: const [0, 0.1, 0.22, 0.5, 0.62, 0.74],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, shine);

    // Étiquette
    canvas.drawCircle(c, r * 0.31, Paint()..color = label);
    canvas.drawCircle(
      c,
      r * 0.31,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withAlpha(40),
    );
    canvas.drawCircle(c, r * 0.045, Paint()..color = const Color(0xFF070707));
  }

  @override
  bool shouldRepaint(covariant _VinylPainter old) => old.label != label;
}
