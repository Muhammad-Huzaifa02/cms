import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tilt_tap_card.dart';
import '../../../data/models/customer_model.dart';

class RecentCustomersSection extends StatelessWidget {
  final List<Customer> customers;
  final VoidCallback onViewAll;
  final Function(Customer) onCustomerTap;

  const RecentCustomersSection({
    super.key,
    required this.customers,
    required this.onViewAll,
    required this.onCustomerTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Inactive':
        return Colors.orange.shade700;
      case 'New':
        return Colors.blue.shade700;
      default:
        return AppColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT CUSTOMERS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.muted,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (customers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black12),
            ),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.people_outline, size: 36, color: AppColors.muted),
                  SizedBox(height: 8),
                  Text(
                    'No customers yet',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: customers.map((c) {
              final initials = c.name.trim().isEmpty
                  ? '?'
                  : c.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

              final isNew = c.createdAt != null &&
                  DateTime.now().difference(c.createdAt!).inDays <= 7;
              final displayStatus = isNew ? 'New' : c.status;
              final badgeColor = _statusColor(displayStatus);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TiltTapCard(
                  onTap: () => onCustomerTap(c),
                  child: Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'avatar-${c.accountNumber}',
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.brand,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.maskedPhone,
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                fontSize: 10,
                                color: badgeColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
