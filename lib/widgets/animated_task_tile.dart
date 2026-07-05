import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// A task row whose checkbox fills in from the center outward, draws a
/// checkmark stroke-by-stroke, and bursts a small confetti pop on
/// completion. Unchecking reverses the whole animation - shrinking the
/// fill and un-drawing the check - with no confetti.
class AnimatedTaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final VoidCallback? onExpandToggle;
  final bool expanded;

  const AnimatedTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onFocus,
    this.onExpandToggle,
    this.expanded = false,
  });

  @override
  State<AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<AnimatedTaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnim;
  late final Animation<double> _checkAnim;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.task.completed ? 1.0 : 0.0,
    );
    _radiusAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );
    _checkAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 500));
  }

  @override
  void didUpdateWidget(covariant AnimatedTaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.completed != widget.task.completed) {
      if (widget.task.completed) {
        _controller.forward(from: _controller.value).whenComplete(() {
          if (mounted) _confettiController.play();
        });
      } else {
        _controller.reverse(from: _controller.value);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (task.hasSubtasks)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: AnimatedRotation(
                turns: widget.expanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
              ),
              onPressed: widget.onExpandToggle,
            )
          else
            const SizedBox(width: 24),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onToggle,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(28, 28),
                        painter: _CircleCheckPainter(
                          radiusProgress: _radiusAnim.value.clamp(0.0, 1.0),
                          checkProgress: _checkAnim.value.clamp(0.0, 1.0),
                          fillColor: AppColors.maroon,
                          checkColor: AppColors.textPrimary,
                          borderColor: task.completed
                              ? AppColors.maroon
                              : AppColors.slateBorder,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 14,
                      gravity: 0.4,
                      minBlastForce: 4,
                      maxBlastForce: 10,
                      colors: AppColors.confettiColors,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: task.completed
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (task.hasSubtasks)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${task.completedSubtaskCount}/${task.totalSubtaskCount} subtasks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (task.reminderIntervalMinutes != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.notifications_active,
                size: 16,
                color: task.isTrulyComplete
                    ? AppColors.textSecondary.withOpacity(0.4)
                    : AppColors.maroonLight,
              ),
            ),
          if (widget.onFocus != null)
            IconButton(
              icon: const Icon(Icons.center_focus_strong,
                  color: AppColors.textSecondary, size: 20),
              onPressed: widget.onFocus,
            ),
        ],
      ),
    );
  }
}

class _CircleCheckPainter extends CustomPainter {
  final double radiusProgress;
  final double checkProgress;
  final Color fillColor;
  final Color checkColor;
  final Color borderColor;

  _CircleCheckPainter({
    required this.radiusProgress,
    required this.checkProgress,
    required this.fillColor,
    required this.checkColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, maxRadius - 1, borderPaint);

    if (radiusProgress > 0) {
      final fillPaint = Paint()..color = fillColor;
      canvas.drawCircle(center, maxRadius * radiusProgress, fillPaint);
    }

    if (checkProgress > 0) {
      final path = Path();
      final p1 = Offset(size.width * 0.26, size.height * 0.54);
      final p2 = Offset(size.width * 0.42, size.height * 0.70);
      final p3 = Offset(size.width * 0.76, size.height * 0.30);
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);

      final metrics = path.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final metric = metrics.first;
        final extractPath =
            metric.extractPath(0, metric.length * checkProgress);

        final checkPaint = Paint()
          ..color = checkColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(extractPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircleCheckPainter oldDelegate) {
    return oldDelegate.radiusProgress != radiusProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.borderColor != borderColor;
  }
}
