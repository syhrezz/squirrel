import 'package:flutter/material.dart';
import '../../theme/dashboard_theme.dart';

/// A skeleton loading placeholder that mimics the shape of content.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = DashboardTheme.radius6,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: DashboardTheme.borderLight,
            borderRadius:
                BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a MetricCard.
class MetricCardSkeleton extends StatelessWidget {
  const MetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.sp20),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radius8),
        border: Border.all(color: DashboardTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 32, height: 32, borderRadius: 6),
              SizedBox(width: 10),
              SkeletonBox(width: 100, height: 12),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(width: 120, height: 24),
          SizedBox(height: 8),
          SkeletonBox(width: 80, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for a table row.
class TableRowSkeleton extends StatelessWidget {
  const TableRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SkeletonBox(width: 24, height: 14),
          const SizedBox(width: 16),
          const Expanded(child: SkeletonBox(width: double.infinity, height: 14)),
          const SizedBox(width: 16),
          const SkeletonBox(width: 60, height: 14),
          const SizedBox(width: 16),
          const SkeletonBox(width: 80, height: 14),
        ],
      ),
    );
  }
}
