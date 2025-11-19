import 'dart:math';
import 'package:flutter/material.dart';

class CircularSlider extends StatelessWidget {
  final double radius;
  final Widget child;
  final bool enabled;

  const CircularSlider({
    super.key,
    required this.radius,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cerchio esterno per indicare l'area di trascinamento
          if (enabled)
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                // Il bordo sarà gestito dal genitore tramite il trascinamento
              ),
            ),

          // Indicatori di posizione attorno al cerchio (come iPod)
          if (enabled)
            ...List.generate(12, (index) {
              final angle = (index * 30) * (pi / 180); // Ogni 30 gradi
              return Transform.translate(
                offset: Offset(
                  cos(angle) * (radius - 15),
                  sin(angle) * (radius - 15),
                ),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA9FFA6).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

          // Contenuto principale
          child,
        ],
      ),
    );
  }
}
