import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An interactive 7-bar customer onboarding growth chart.
/// Expandable with summary statistics, day selection, and staggered bar animations.
class GrowthChart extends StatefulWidget {
  final List<int> dailyCounts; // oldest -> newest, see CustomerService.getGrowthLast7Days
  final bool initialExpanded;

  const GrowthChart({
    super.key,
    required this.dailyCounts,
    this.initialExpanded = true,
  });

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  late bool _expanded = widget.initialExpanded;
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final dailyCounts = widget.dailyCounts;
    final maxVal = dailyCounts.isEmpty ? 1 : dailyCounts.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final labels = _last7DayLabels();
    final totalWeek = dailyCounts.fold<int>(0, (sum, val) => sum + val);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppColors.brand, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7-Day Onboarding Trend',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+$totalWeek new customer${totalWeek == 1 ? '' : 's'} this week',
                          style: TextStyle(
                            fontSize: 11,
                            color: totalWeek > 0 ? AppColors.success : AppColors.muted,
                            fontWeight: totalWeek > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+$totalWeek',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.brand,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (_selectedBarIndex != null && _selectedBarIndex! < dailyCounts.length) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_fullDayName(_selectedBarIndex!)}: ${dailyCounts[_selectedBarIndex!]} registered',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedBarIndex = null),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    height: 88,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(dailyCounts.length, (i) {
                        final fraction = dailyCounts[i] / maxVal;
                        final isSelected = _selectedBarIndex == i;
                        final isToday = i == dailyCounts.length - 1;

                        Color barColor;
                        if (isSelected) {
                          barColor = AppColors.brandDeep;
                        } else if (isToday) {
                          barColor = AppColors.gold;
                        } else {
                          barColor = AppColors.brand.withValues(alpha: 0.75);
                        }

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selectedBarIndex = i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${dailyCounts[i]}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isSelected ? AppColors.brandDeep : AppColors.muted,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: fraction.clamp(0.0, 1.0)),
                                    duration: Duration(milliseconds: 500 + i * 50),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, child) {
                                      return FractionallySizedBox(
                                        heightFactor: v == 0 ? 0.04 : v,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          decoration: BoxDecoration(
                                            color: barColor,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.brand.withValues(alpha: 0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, -1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(labels.length, (i) {
                      final isSelected = _selectedBarIndex == i;
                      return Expanded(
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.brandDeep : AppColors.muted,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 240),
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

  String _fullDayName(int index) {
    const names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - index));
    final name = names[day.weekday % 7];
    if (index == 6) return 'Today ($name)';
    if (index == 5) return 'Yesterday ($name)';
    return name;
  }
}

/// Shimmer-free lightweight skeleton for the chart's loading state.
class GrowthChartSkeleton extends StatelessWidget {
  const GrowthChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_graph_rounded, color: AppColors.brand, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '7-Day Onboarding Trend',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
          ),
        ],
      ),
    );
  }
}
