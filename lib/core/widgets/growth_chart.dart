import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A simple 7-bar growth chart drawn with plain Containers — deliberately
/// not a charting package dependency. Seven numbers don't need a charting
/// library; adding one just to draw seven bars would be exactly the kind
/// of unnecessary dependency the brief for this feature warned against.
/// Animates once, drawing each bar from zero up to its real height.
class GrowthChart extends StatelessWidget {
  final List<int> dailyCounts; // oldest -> newest, see CustomerService.getGrowthLast7Days
  const GrowthChart({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final maxVal = dailyCounts.isEmpty ? 1 : dailyCounts.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final labels = _last7DayLabels();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Customers — Last 7 Days', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dailyCounts.length, (i) {
                final fraction = dailyCounts[i] / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${dailyCounts[i]}', style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: fraction.clamp(0.0, 1.0)),
                          duration: Duration(milliseconds: 500 + i * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, child) {
                            return FractionallySizedBox(
                              heightFactor: v == 0 ? 0.02 : v,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: i == dailyCounts.length - 1 ? AppColors.gold : AppColors.brand.withValues(alpha: 0.75),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: labels
                .map((l) => Expanded(
                      child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _last7DayLabels() {
    const names = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return names[day.weekday % 7];
    });
  }
}

/// Shimmer-free lightweight skeleton for the chart's loading state (a
/// loading indicator is enough here — the chart itself is small and loads
/// fast via 7 count() queries).
class GrowthChartSkeleton extends StatelessWidget {
  const GrowthChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
    );
  }
}
