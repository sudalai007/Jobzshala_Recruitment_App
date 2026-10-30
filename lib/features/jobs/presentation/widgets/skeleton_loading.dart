import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SkeletonLoadingList extends StatelessWidget {
  const SkeletonLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonJobCard(),
    );
  }
}

class SkeletonJobCard extends StatefulWidget {
  const SkeletonJobCard({super.key});

  @override
  State<SkeletonJobCard> createState() => _SkeletonJobCardState();
}

class _SkeletonJobCardState extends State<SkeletonJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({required double width, required double height, double radius = 6}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _box(width: 180, height: 18),
                _box(width: 80, height: 22, radius: 8),
              ],
            ),
            const SizedBox(height: 10),
            _box(width: 140, height: 14),
            const SizedBox(height: 6),
            _box(width: 100, height: 12),
            const SizedBox(height: 12),
            _box(width: 160, height: 24, radius: 6),
            const SizedBox(height: 10),
            Row(
              children: [
                _box(width: 70, height: 18, radius: 4),
                const SizedBox(width: 6),
                _box(width: 80, height: 18, radius: 4),
                const SizedBox(width: 6),
                _box(width: 75, height: 18, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

