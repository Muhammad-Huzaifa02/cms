enum GrowthPeriod {
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
}

class GrowthPoint {
  final String label;
  final int count;
  final DateTime date;

  const GrowthPoint({
    required this.label,
    required this.count,
    required this.date,
  });
}

class DashboardStats {
  final int totalCustomers;
  final int newThisMonth;
  final int activeCustomers;
  final int inactiveCustomers;
  final double? monthlyGrowthPercentage;
  final int newLastMonth;

  const DashboardStats({
    required this.totalCustomers,
    required this.newThisMonth,
    required this.activeCustomers,
    required this.inactiveCustomers,
    this.monthlyGrowthPercentage,
    this.newLastMonth = 0,
  });
}
