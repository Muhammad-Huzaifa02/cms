import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tilt_tap_card.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddCustomer;
  final VoidCallback onViewAllCustomers;
  final VoidCallback onReports;
  final VoidCallback onSettings;

  const QuickActionsSection({
    super.key,
    required this.onAddCustomer,
    required this.onViewAllCustomers,
    required this.onReports,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                label: 'Add',
                icon: Icons.person_add_alt_1_outlined,
                color: AppColors.gold,
                onTap: onAddCustomer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                label: 'Customers',
                icon: Icons.people_outline,
                color: AppColors.brand,
                onTap: onViewAllCustomers,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                label: 'Reports',
                icon: Icons.analytics_outlined,
                color: const Color(0xFF6C5CE7),
                onTap: onReports,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                label: 'Settings',
                icon: Icons.settings_outlined,
                color: const Color(0xFF00CEC9),
                onTap: onSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TiltTapCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
