import 'dart:math';
import 'package:flutter/material.dart';

class AmbientOrbs extends StatefulWidget {
  final Color color;
  final int orbCount;
  final double maxOpacity;

  const AmbientOrbs({
    super.key,
    this.color = const Color(0xFF2563EB),
    this.orbCount = 3,
    this.maxOpacity = 0.08,
  });

  @override
  State<AmbientOrbs> createState() => _AmbientOrbsState();
}

class _AmbientOrbsState extends State<AmbientOrbs> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _xAnims;
  late List<Animation<double>> _yAnims;
  late List<_OrbData> _orbs;

  static final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _orbs = List.generate(widget.orbCount, (i) => _OrbData(
      xBase: 0.1 + _rng.nextDouble() * 0.8,
      yBase: 0.1 + _rng.nextDouble() * 0.8,
      size:  140 + _rng.nextDouble() * 120,
      xRange: 0.05 + _rng.nextDouble() * 0.08,
      yRange: 0.04 + _rng.nextDouble() * 0.06,
      duration: Duration(milliseconds: 5000 + _rng.nextInt(4000)),
    ));

    _ctrls = _orbs.map((o) => AnimationController(vsync: this, duration: o.duration)..repeat(reverse: true)).toList();

    _xAnims = List.generate(widget.orbCount, (i) =>
      Tween<double>(begin: -_orbs[i].xRange, end: _orbs[i].xRange)
        .animate(CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut)));

    _yAnims = List.generate(widget.orbCount, (i) =>
      Tween<double>(begin: -_orbs[i].yRange, end: _orbs[i].yRange)
        .animate(CurvedAnimation(parent: _ctrls[i], curve: Curves.easeInOut)));
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(_ctrls),
        builder: (_, __) => Stack(
          children: List.generate(widget.orbCount, (i) {
            final orb = _orbs[i];
            return Positioned.fill(
              child: LayoutBuilder(builder: (_, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final cx = (orb.xBase + _xAnims[i].value) * w;
                final cy = (orb.yBase + _yAnims[i].value) * h;
                return Stack(children: [
                  Positioned(
                    left: cx - orb.size / 2,
                    top:  cy - orb.size / 2,
                    child: Container(
                      width: orb.size,
                      height: orb.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withValues(alpha: widget.maxOpacity),
                            widget.color.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]);
              }),
            );
          }),
        ),
      ),
    );
  }
}

class _OrbData {
  final double xBase, yBase, size, xRange, yRange;
  final Duration duration;
  const _OrbData({required this.xBase, required this.yBase, required this.size, required this.xRange, required this.yRange, required this.duration});
}
