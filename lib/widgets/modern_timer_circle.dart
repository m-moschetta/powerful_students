import 'dart:math';
import 'package:flutter/material.dart';

class ModernTimerCircle extends StatefulWidget {
  final double progress;
  final double radius;
  final double trackWidth;
  final double progressWidth;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;
  final double thumbRadius;
  final bool isDraggable;
  final ValueChanged<double>? onProgressChanged;
  final Widget? center;

  const ModernTimerCircle({
    super.key,
    required this.progress,
    required this.radius,
    this.trackWidth = 6.0,
    this.progressWidth = 12.0,
    required this.trackColor,
    required this.progressColor,
    required this.thumbColor,
    this.thumbRadius = 16.0,
    this.isDraggable = false,
    this.onProgressChanged,
    this.center,
  });

  @override
  State<ModernTimerCircle> createState() => _ModernTimerCircleState();
}

class _ModernTimerCircleState extends State<ModernTimerCircle> {
  void _handlePan(Offset localPosition) {
    if (!widget.isDraggable || widget.onProgressChanged == null) return;
    
    // Center of the circle
    final center = Offset(widget.radius, widget.radius);
    
    // Calculate angle from center to touch point
    // We subtract pi/2 so that 0 starts at the top
    final angle = atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
    
    // Normalize angle to [0, 2*pi]
    var normalizedAngle = angle + pi / 2;
    if (normalizedAngle < 0) {
      normalizedAngle += 2 * pi;
    }
    
    // Calculate progress [0, 1]
    double newProgress = normalizedAngle / (2 * pi);
    
    // Snap to 60 steps (minutes)
    int minutes = (newProgress * 60).round();
    if (minutes == 0) minutes = 60;
    
    widget.onProgressChanged!(minutes / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _handlePan(details.localPosition),
      onPanUpdate: (details) => _handlePan(details.localPosition),
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center widget
            if (widget.center != null) widget.center!,
            
            // Circular progress and thumb
            CustomPaint(
              size: Size(widget.radius * 2, widget.radius * 2),
              painter: _TimerPainter(
                progress: widget.progress,
                trackWidth: widget.trackWidth,
                progressWidth: widget.progressWidth,
                trackColor: widget.trackColor,
                progressColor: widget.progressColor,
                thumbColor: widget.thumbColor,
                thumbRadius: widget.thumbRadius,
                showThumb: widget.isDraggable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final double trackWidth;
  final double progressWidth;
  final Color trackColor;
  final Color progressColor;
  final Color thumbColor;
  final double thumbRadius;
  final bool showThumb;

  _TimerPainter({
    required this.progress,
    required this.trackWidth,
    required this.progressWidth,
    required this.trackColor,
    required this.progressColor,
    required this.thumbColor,
    required this.thumbRadius,
    required this.showThumb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - progressWidth) / 2;
    
    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;
    canvas.drawCircle(center, radius, trackPaint);
    
    // Draw progress
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth
      ..strokeCap = StrokeCap.round;
      
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start at top
      sweepAngle,
      false,
      progressPaint,
    );
    
    // Draw thumb
    if (showThumb) {
      final thumbAngle = -pi / 2 + sweepAngle;
      final thumbCenter = Offset(
        center.dx + radius * cos(thumbAngle),
        center.dy + radius * sin(thumbAngle),
      );
      
      final thumbPaint = Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill;
        
      final thumbBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
        
      canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);
      canvas.drawCircle(thumbCenter, thumbRadius, thumbBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.showThumb != showThumb ||
           oldDelegate.trackColor != trackColor ||
           oldDelegate.progressColor != progressColor;
  }
}