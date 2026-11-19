import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../data/services/activity_service.dart';
import '../../../core/theme/app_theme.dart';

/// Live Banking Activity Log & Audit Ledger with Chronological Timeline Nodes.
class ActivityLogScreen extends StatelessWidget {
  final AppUser currentUser;
  const ActivityLogScreen({super.key, required this.currentUser});

  Color _actionColor(ActivityAction a) {
    switch (a) {
      case ActivityAction.customerCreated:
      case ActivityAction.staffCreated:
        return AppColors.brand;
      case ActivityAction.customerDeleted:
      case ActivityAction.staffRemoved:
        return AppColors.danger;
      case ActivityAction.export:
        return const Color(0xFF2563EB);
      default:
        return AppColors.gold;
    }
  }

  IconData _actionIcon(ActivityAction a) {
    switch (a) {
      case ActivityAction.customerCreated:
        return Icons.person_add_rounded;
      case ActivityAction.customerUpdated:
        return Icons.edit_note_rounded;
      case ActivityAction.customerDeleted:
        return Icons.person_remove_rounded;
      case ActivityAction.staffCreated:
        return Icons.shield_rounded;
      case ActivityAction.staffPermissionsChanged:
        return Icons.security_rounded;
      case ActivityAction.staffRemoved:
        return Icons.remove_moderator_rounded;
      case ActivityAction.export:
        return Icons.file_download_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!currentUser.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access only.')));
    }
    final service = ActivityService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LiveLedgerPulseNode(color: AppColors.brand, size: 8),
                SizedBox(width: 8),
                Text(
                  'LIVE AUDIT',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ActivityLogEntry>>(
        stream: service.recent(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(
              child: Text('No activity yet.', style: TextStyle(color: AppColors.muted)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final isFirst = i == 0;
              final isLast = i == entries.length - 1;
              final color = _actionColor(e.action);
              final icon = _actionIcon(e.action);
              final time = e.timestamp != null
                  ? DateFormat('MMM d, h:mm:ss a').format(e.timestamp!)
                  : 'Just now';

              final delayMs = (i * 35).clamp(0, 450);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + delayMs),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Opacity(
                    opacity: animValue.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset((1.0 - animValue) * 16.0, 0),
                      child: child,
                    ),
                  );
                },
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── TIMELINE STEM & NODE ──
                      SizedBox(
                        width: 32,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Vertical timeline line
                            Positioned(
                              top: isFirst ? 16 : 0,
                              bottom: isLast ? null : 0,
                              height: isLast ? 16 : null,
                              child: Container(
                                width: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withValues(alpha: isFirst ? 0.8 : 0.35),
                                      AppColors.brand.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Node marker
                            Positioned(
                              top: 14,
                              child: isFirst
                                  ? _LiveLedgerPulseNode(color: color, size: 14)
                                  : Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: color, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ── AUDIT LEDGER ENTRY CARD ──
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.82),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFirst
                                  ? color.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.95),
                              width: isFirst ? 1.4 : 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isFirst
                                    ? color.withValues(alpha: 0.08)
                                    : AppColors.brandDeep.withValues(alpha: 0.04),
                                blurRadius: isFirst ? 14 : 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, size: 18, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.ink,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: e.performedByName,
                                            style: const TextStyle(fontWeight: FontWeight.w800),
                                          ),
                                          TextSpan(
                                            text: ' ${e.action.label} ',
                                            style: const TextStyle(color: Color(0xFF4B5563)),
                                          ),
                                          TextSpan(
                                            text: e.targetId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.brandDeep,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: AppColors.muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.muted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (isFirst) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'LATEST',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: color,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Pulsing Ledger Node Indicator with Expanding Radar Aura.
class _LiveLedgerPulseNode extends StatefulWidget {
  final Color color;
  final double size;

  const _LiveLedgerPulseNode({required this.color, this.size = 12});

  @override
  State<_LiveLedgerPulseNode> createState() => _LiveLedgerPulseNodeState();
}

class _LiveLedgerPulseNodeState extends State<_LiveLedgerPulseNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = _pulse.value;
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar pulse
              Container(
                width: widget.size + (widget.size * v),
                height: widget.size + (widget.size * v),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (0.35 * (1.0 - v)).clamp(0.0, 1.0)),
                ),
              ),
              // Inner solid node
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
