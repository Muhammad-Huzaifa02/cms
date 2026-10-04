import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SearchFieldSelector extends StatelessWidget {
  final String selectedField;
  final ValueChanged<String> onFieldSelected;

  static const List<String> fields = [
    'All',
    'Account Title',
    'Account ID',
    'Phone Number',
    'CNIC',
  ];

  const SearchFieldSelector({
    super.key,
    required this.selectedField,
    required this.onFieldSelected,
  });

  IconData _iconForField(String field) {
    switch (field) {
      case 'Account Title':
        return Icons.person_outline;
      case 'Account ID':
        return Icons.badge_outlined;
      case 'Phone Number':
        return Icons.phone_outlined;
      case 'CNIC':
        return Icons.credit_card_outlined;
      default:
        return Icons.manage_search_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SEARCH FIELD TARGET',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: fields.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final field = fields[index];
              final isSelected = field == selectedField;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onFieldSelected(field),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.brand : Colors.black12,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brand.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForField(field),
                          size: 15,
                          color: isSelected ? Colors.white : AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          field,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
