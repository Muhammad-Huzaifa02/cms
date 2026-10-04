import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/dashboard_stats_model.dart';

class CustomerGrowthChart extends StatelessWidget {
  final List<GrowthPoint> dataPoints;
  final GrowthPeriod selectedPeriod;
  final ValueChanged<GrowthPeriod> onPeriodChanged;
  final bool isLoading;

  const CustomerGrowthChart({
    super.key,
    required this.dataPoints,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  String _periodLabel(GrowthPeriod period) {
    switch (period) {
      case GrowthPeriod.thisWeek:
        return 'This Week';
      case GrowthPeriod.thisMonth:
        return 'This Month';
      case GrowthPeriod.lastMonth:
        return 'Last Month';
      case GrowthPeriod.last3Months:
        return 'Last 3 Months';
      case GrowthPeriod.thisYear:
        return 'This Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = dataPoints.fold<int>(0, (max, p) => math.max(max, p.count));
    final displayMax = maxVal == 0 ? 5 : maxVal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.show_chart, size: 18, color: AppColors.brand),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Growth',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                            ),
                            Text(
                              'Acquisitions over time',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<GrowthPeriod>(
                      value: selectedPeriod,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.brand, size: 18),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brand),
                      items: GrowthPeriod.values.map((p) {
                        return DropdownMenuItem<GrowthPeriod>(
                          value: p,
                          child: Text(_periodLabel(p)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) onPeriodChanged(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 2.5),
                ),
              )
            else if (dataPoints.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'No growth data for this period',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y-axis labels
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$displayMax', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          Text('${(displayMax / 2).round()}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          const Text('0', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const minItemWidth = 38.0;
                          final totalWidthNeeded = dataPoints.length * minItemWidth;
                          final needsScroll = totalWidthNeeded > constraints.maxWidth;
                          final itemWidth = needsScroll ? minItemWidth : (constraints.maxWidth / dataPoints.length);

                          Widget chartRow = Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: dataPoints.map((point) {
                              final ratio = point.count / displayMax;
                              final barHeight = math.max(6.0, 85.0 * ratio);
                              final barWidth = math.max(10.0, math.min(24.0, itemWidth - 10.0));

                              return SizedBox(
                                width: itemWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (point.count > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '${point.count}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                      ),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: barHeight),
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, heightVal, child) {
                                        return Container(
                                          width: barWidth,
                                          height: heightVal,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [AppColors.brand, AppColors.brandLight],
                                            ),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.brand.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      point.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );

                          if (needsScroll) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: totalWidthNeeded,
                                child: chartRow,
                              ),
                            );
                          }

                          return chartRow;
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
