import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/tilt_tap_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/dashboard_stat_card.dart';
import '../../../core/widgets/error_state.dart';
import '../../customers/views/customer_detail_screen.dart';
import '../../customers/views/add_customer_screen.dart';
import '../../customers/views/search_customer_screen.dart';
import '../../customers/views/customer_management_screen.dart';
import 'staff_management_screen.dart';
import 'activity_log_screen.dart';
import '../../profile/views/edit_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _customerService = CustomerService();
  final _exportService = ExportService();
  final _authService = AuthService();
  final _updateService = AppUpdateService();
  bool _exporting = false;
  late Stream<List<Customer>> _recentCustomersStream = _customerService.recentCustomers();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInAppUpdate());
  }

  Future<void> _checkInAppUpdate() async {
    final info = await _updateService.checkForUpdate();
    if (!mounted || !info.hasUpdate) return;

    showDialog<void>(
      context: context,
      barrierDismissible: !info.isForced,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_rounded, color: AppColors.brand, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v${info.latestVersion} (Current: v${info.currentVersion})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              info.releaseNotes.isNotEmpty ? info.releaseNotes : 'A new enhanced version of CMS is available with performance improvements and security updates.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          if (!info.isForced)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download Update', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () {
              Navigator.pop(ctx);
              if (info.downloadUrl.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: info.downloadUrl));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(info.downloadUrl.isNotEmpty
                      ? 'Download link copied to clipboard. Open in browser to install.'
                      : 'Contact your branch administrator for the v${info.latestVersion} APK package.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Fetched once per Dashboard visit (not per rebuild) — both use
  // Firestore COUNT aggregation, so this is two small server-side counts,
  // never a download of the whole customers collection.
  late Future<List<int>> _statsFuture = _loadStats();

  Future<List<int>> _loadStats() => Future.wait([
        _customerService.getTotalCustomersCount(),
        _customerService.getNewCustomersThisMonthCount(),
      ]);

  Future<void> _handleRefresh() async {
    setState(() {
      _statsFuture = _loadStats();
      _recentCustomersStream = _customerService.recentCustomers();
    });
    try {
      await _statsFuture;
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (_) {}
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await _authService.signOut();
  }

  Future<void> _logoutAndExit() async {
    await _authService.signOut();
    await SystemNavigator.pop();
  }

  void _openSearch() {
    push3D(context, SearchCustomerScreen(currentUser: widget.currentUser));
  }

  Future<void> _runBackfill() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    try {
      final count = await _customerService.backfillSearchFields(widget.currentUser);
      if (!mounted) return;
      Navigator.of(context).pop(); // close spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search index synced for $count customer${count == 1 ? '' : 's'}.')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final customers = await _customerService.recentCustomers(limit: 5000).first;
      final file = format == 'excel'
          ? await _exportService.exportToExcel(customers, widget.currentUser)
          : format == 'pdf'
              ? await _exportService.exportToPdf(customers, widget.currentUser)
              : await _exportService.exportToJsonBackup(customers, widget.currentUser);
      
      final shaDigest = await _exportService.calculateFileSha256(file);
      final shortSha = shaDigest.length >= 12 ? shaDigest.substring(0, 12) : shaDigest;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.brandDeep,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Export verified • SHA-256: $shortSha...',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await _exportService.shareFile(
        file,
        subject: format == 'json'
            ? 'CMS Database Backup Vault (SHA256: $shortSha)'
            : 'CMS Customer Export (SHA256: $shortSha)',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width.clamp(280.0, 330.0),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
            border: Border(
              right: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.50),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(6, 0),
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(2, 0),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 30,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Stack(
                children: [
                  // Layer 1: Deep obsidian-emerald glass gradient background
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xF502221C),
                            Color(0xF0032B24),
                            Color(0xF804362E),
                            Color(0xF2011915),
                          ],
                          stops: [0.0, 0.35, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Layer 2: Radiant atmospheric brand glow orbs
                  // Top orb (shining behind profile)
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brandLight.withValues(alpha: 0.45),
                            AppColors.brand.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                  // Middle orb (illuminating navigation items)
                  Positioned(
                    top: 260,
                    left: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brand.withValues(alpha: 0.35),
                            AppColors.brandDeep.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                  // Bottom orb (glowing near sign-out footer)
                  Positioned(
                    bottom: -30,
                    right: -40,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.32),
                            const Color(0xFFD4AF37).withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),

                  // Layer 3: Glass content column
                  Column(
                    children: [
                      // ── EXECUTIVE FROSTED PROFILE HEADER ──
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          18,
                          MediaQuery.of(context).padding.top + 16,
                          18,
                          18,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              width: 1.0,
                            ),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandLight.withValues(alpha: 0.22),
                              AppColors.brandDeep.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App branding chip with glowing gold outline
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandDeep.withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.55),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_rounded, size: 12.5, color: AppColors.gold),
                                  SizedBox(width: 6),
                                  Text(
                                    'CUSTOMER MANAGEMENT SYSTEM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // User Info Glass Card
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(context);
                                push3D(context, EditProfileScreen(currentUser: user));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.10),
                                      Colors.white.withValues(alpha: 0.03),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandDeep.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // User Avatar
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: user.isAdmin
                                            ? const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [Color(0xFFD4AF37), AppColors.gold],
                                              )
                                            : const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [AppColors.brandLight, AppColors.brand],
                                              ),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (user.isAdmin ? AppColors.gold : AppColors.brandLight)
                                                .withValues(alpha: 0.55),
                                            blurRadius: 14,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        user.name.trim().isNotEmpty
                                            ? user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email ?? user.phone ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: user.isAdmin
                                                  ? AppColors.gold.withValues(alpha: 0.25)
                                                  : AppColors.brandLight.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: user.isAdmin
                                                    ? AppColors.gold.withValues(alpha: 0.65)
                                                    : AppColors.brandLight.withValues(alpha: 0.65),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  user.isAdmin ? Icons.shield_rounded : Icons.badge_outlined,
                                                  size: 10.5,
                                                  color: user.isAdmin ? AppColors.gold : Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.isAdmin ? 'ADMINISTRATOR' : 'BANKING STAFF',
                                                  style: TextStyle(
                                                    color: user.isAdmin ? AppColors.gold : Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 13,
                                      color: AppColors.gold.withValues(alpha: 0.85),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── SCROLLABLE NAVIGATION LIST ──
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          children: [
                            const _ModernDrawerSectionHeader('OVERVIEW'),
                            _ModernGlassDrawerTile(
                              icon: Icons.dashboard_rounded,
                              title: 'Dashboard',
                              isSelected: true,
                              onTap: () => Navigator.pop(context),
                            ),
                            if (user.can('view'))
                              _ModernGlassDrawerTile(
                                icon: Icons.people_alt_outlined,
                                title: 'Customer Management',
                                subtitle: 'Search & view records',
                                onTap: () {
                                  Navigator.pop(context);
                                  push3D(context, CustomerManagementScreen(currentUser: user));
                                },
                              ),

                            if (user.isAdmin) ...[
                              const SizedBox(height: 6),
                              const _ModernDrawerSectionHeader('ADMINISTRATION'),
                              _ModernGlassDrawerTile(
                                icon: Icons.badge_outlined,
                                title: 'Staff Management',
                                subtitle: 'Roles, accounts & permissions',
                                onTap: () {
                                  Navigator.pop(context);
                                  push3D(context, StaffManagementScreen(currentUser: user));
                                },
                              ),
                              _ModernGlassDrawerTile(
                                icon: Icons.receipt_long_outlined,
                                title: 'Activity Audit Log',
                                subtitle: 'Security & compliance trail',
                                onTap: () {
                                  Navigator.pop(context);
                                  push3D(context, ActivityLogScreen(currentUser: user));
                                },
                              ),

                              const SizedBox(height: 6),
                              const _ModernDrawerSectionHeader('DATA & EXPORT'),
                              _ModernGlassDrawerTile(
                                icon: Icons.table_chart_outlined,
                                iconColor: const Color(0xFF34D399),
                                title: 'Export to Excel (.xlsx)',
                                onTap: () {
                                  Navigator.pop(context);
                                  _export('excel');
                                },
                              ),
                              _ModernGlassDrawerTile(
                                icon: Icons.picture_as_pdf_outlined,
                                iconColor: const Color(0xFFF87171),
                                title: 'Export to PDF Document',
                                onTap: () {
                                  Navigator.pop(context);
                                  _export('pdf');
                                },
                              ),
                              _ModernGlassDrawerTile(
                                icon: Icons.backup_outlined,
                                iconColor: const Color(0xFF60A5FA),
                                title: 'Backup Database (.json)',
                                subtitle: 'Full-fidelity disaster recovery snapshot',
                                onTap: () {
                                  Navigator.pop(context);
                                  _export('json');
                                },
                              ),

                              const SizedBox(height: 6),
                              const _ModernDrawerSectionHeader('SYSTEM MAINTENANCE'),
                              _ModernGlassDrawerTile(
                                icon: Icons.sync_rounded,
                                iconColor: AppColors.gold,
                                title: 'Sync Search Index',
                                subtitle: 'Re-index legacy records for search',
                                onTap: () {
                                  Navigator.pop(context);
                                  _runBackfill();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── SAFE BOTTOM FOOTER ──
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.gold.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          12,
                          14,
                          MediaQuery.of(context).padding.bottom > 0
                              ? MediaQuery.of(context).padding.bottom + 8
                              : 16,
                        ),
                        child: Column(
                          children: [
                            _ModernGlassSignOutButton(
                              onTap: () {
                                Navigator.pop(context);
                                _confirmSignOut();
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 12,
                                  color: AppColors.gold.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'CMS v1.0.0 • Secured Banking Portal',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 152,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.brandDeep,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: const Border(),
              leading: Container(
                margin: const EdgeInsets.only(left: 12),
                child: Center(
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_exporting)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Center(
                      child: Tooltip(
                        message: 'Logout & Exit',
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _logoutAndExit,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF022B24),
                        AppColors.brandDeep,
                        AppColors.brand,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Soft ambient light
                      Positioned(
                        left: -35,
                        top: -35,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      // Executive Profile Header Row
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          MediaQuery.of(context).padding.top + kToolbarHeight - 2,
                          20,
                          0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // User Initials Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: user.isAdmin
                                      ? [const Color(0xFFD4AF37), AppColors.gold]
                                      : [AppColors.brandLight, AppColors.brand],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user.name.trim().isNotEmpty
                                    ? user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // User Greeting, Name & Role Badge
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTimeGreeting(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: user.isAdmin
                                              ? AppColors.gold.withValues(alpha: 0.25)
                                              : Colors.white.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: user.isAdmin ? AppColors.gold : Colors.white.withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              user.isAdmin ? Icons.shield_rounded : Icons.badge_outlined,
                                              size: 11.5,
                                              color: user.isAdmin ? AppColors.gold : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.isAdmin ? 'ADMIN' : 'STAFF',
                                              style: TextStyle(
                                                color: user.isAdmin ? AppColors.gold : Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Seamless header background continuation matching the top bar gradient
                // Reaches 4px upward to prevent any subpixel raster gap with SliverAppBar
                Positioned(
                  top: -4,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF022B24),
                          AppColors.brandDeep,
                          AppColors.brand,
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(0.06 * (1 - value))
                          // ignore: deprecated_member_use
                          ..scale(0.97 + (0.03 * value), 0.97 + (0.03 * value), 1.0),
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandDeep.withValues(alpha: 0.16),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.10),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: TextField(
                            readOnly: true,
                            showCursor: false,
                            onTap: _openSearch,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search customer…',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
                              prefixIcon: const Icon(Icons.search, size: 24, color: AppColors.brand),
                              suffixIcon: const Icon(Icons.arrow_forward, size: 22),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.95), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.95), width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.92),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<int>>(
                future: _statsFuture,
                builder: (context, snap) {
                  final loading = snap.connectionState != ConnectionState.done;
                  if (!loading && snap.hasError) {
                    return ErrorStateWidget(
                      message: 'Unable to load dashboard statistics.',
                      onRetry: () => setState(() => _statsFuture = _loadStats()),
                    );
                  }
                  final total = snap.data?[0] ?? 0;
                  final newThisMonth = snap.data?[1] ?? 0;
                  final cards = [
                    loading
                        ? const DashboardStatSkeleton()
                        : DashboardStatCard(
                            icon: Icons.people_alt_outlined,
                            label: 'Total Customers',
                            value: total,
                            accent: AppColors.brand,
                          ),
                    loading
                        ? const DashboardStatSkeleton()
                        : DashboardStatCard(
                            icon: Icons.person_add_alt_1_outlined,
                            label: 'New This Month',
                            value: newThisMonth,
                            accent: AppColors.success,
                            caption: newThisMonth > 0 ? '+$newThisMonth added' : null,
                            captionColor: AppColors.success,
                          ),
                  ];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context).scale(1);
                      final stack = constraints.maxWidth < 440 || scale > 1.25;
                      if (stack) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [cards[0], const SizedBox(height: 12), cards[1]],
                        );
                      }
                      return Row(children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[1]),
                      ]);
                    },
                  );
                },
              ),
            ),
          ),
          StreamBuilder<List<Customer>>(
            stream: _recentCustomersStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: ShimmerLoading(count: 6),
                );
              }
              // A genuine failure (permission-denied, offline, etc.) must
              // never be mistaken for "the list is just empty" — that was
              // a real bug here: snap.data ?? [] silently turned any error
              // into the friendly "No customers yet" empty state.
              if (snap.hasError) {
                return SliverErrorState(
                  message: 'Unable to load customers. Check your connection and try again.',
                  onRetry: () => setState(() {}),
                );
              }
              final customers = snap.data ?? [];
              if (customers.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No customers yet.',
                          style: TextStyle(color: AppColors.muted, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the + button to add the first one.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
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
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.brand.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${customers.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brand,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (user.can('view'))
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => push3D(context, CustomerManagementScreen(currentUser: user)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View All',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.brand,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.brand),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }
                      final c = customers[index - 1];
                      return _CustomerTile(
                        customer: c,
                        onTap: () => push3D(context, CustomerDetailScreen(customer: c, currentUser: user)),
                      );
                    },
                    childCount: customers.length + 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
    floatingActionButton: user.can('add')
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: FloatingActionButton(
                elevation: 8,
                backgroundColor: AppColors.gold,
                onPressed: () => push3D(context, AddCustomerScreen(currentUser: user)),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }

}

class _ModernDrawerSectionHeader extends StatelessWidget {
  final String title;
  const _ModernDrawerSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernGlassDrawerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernGlassDrawerTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_ModernGlassDrawerTile> createState() => _ModernGlassDrawerTileState();
}

class _ModernGlassDrawerTileState extends State<_ModernGlassDrawerTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;
    final hovered = _isHovered;
    final primaryColor = widget.iconColor ?? AppColors.brandLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(hovered && !active ? 4.0 : 0.0, 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x5E10866E),
                      Color(0x400A6B57),
                      Color(0x22033D33),
                    ],
                  )
                : (hovered
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.brandLight.withValues(alpha: 0.24),
                          AppColors.brand.withValues(alpha: 0.12),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.01),
                        ],
                      )),
            border: Border.all(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.75)
                  : (hovered
                      ? AppColors.brandLight.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.07)),
              width: active ? 1.4 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.40),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 24,
                    ),
                  ]
                : (hovered
                    ? [
                        BoxShadow(
                          color: AppColors.brandLight.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              splashColor: AppColors.brandLight.withValues(alpha: 0.2),
              highlightColor: AppColors.gold.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    // Glowing Left Indicator Pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 3.5 : (hovered ? 2.5 : 0.0),
                      height: 22,
                      margin: EdgeInsets.only(right: (active || hovered) ? 10 : 0),
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : AppColors.brandLight,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: (active ? AppColors.gold : AppColors.brandLight).withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // Icon Glass Squircle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: active
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandLight,
                                  AppColors.brandDeep,
                                ],
                              )
                            : (hovered
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryColor.withValues(alpha: 0.35),
                                      AppColors.brandDeep.withValues(alpha: 0.25),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryColor.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.04),
                                    ],
                                  )),
                        border: Border.all(
                          color: active
                              ? AppColors.gold.withValues(alpha: 0.8)
                              : (hovered
                                  ? AppColors.brandLight.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.12)),
                          width: 1.0,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.brandLight.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: active ? Colors.white : (hovered ? AppColors.gold : primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : (hovered ? Colors.white : const Color(0xFFE2EFEA)),
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: active
                                    ? const Color(0xFFD4EAE2)
                                    : (hovered ? const Color(0xFFC7E2D8) : const Color(0xFF9CB8AF)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Trailing indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(hovered ? 2.0 : 0.0, 0, 0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: active
                            ? AppColors.gold
                            : (hovered
                                ? AppColors.brandLight
                                : Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernGlassSignOutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ModernGlassSignOutButton({required this.onTap});

  @override
  State<_ModernGlassSignOutButton> createState() => _ModernGlassSignOutButtonState();
}

class _ModernGlassSignOutButtonState extends State<_ModernGlassSignOutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isHovered
                ? [
                    AppColors.danger.withValues(alpha: 0.28),
                    AppColors.brandDeep.withValues(alpha: 0.20),
                  ]
                : [
                    AppColors.danger.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          border: Border.all(
            color: _isHovered
                ? AppColors.danger.withValues(alpha: 0.65)
                : AppColors.danger.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.brandDeep.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            splashColor: AppColors.danger.withValues(alpha: 0.25),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded, color: Color(0xFFFDA4AF), size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  LinearGradient _getAvatarGradient(String accountType) {
    final lower = accountType.toLowerCase();
    if (lower.contains('saving')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandDeep, AppColors.brand],
      );
    } else if (lower.contains('current')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      );
    } else if (lower.contains('business') || lower.contains('corporate')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF78350F), Color(0xFFD97706)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.brandDeep, AppColors.brandLight],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'dormant':
        return const Color(0xFFD97706);
      case 'blocked':
        return AppColors.danger;
      case 'inactive':
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = customer.accountTitle.trim().isNotEmpty
        ? customer.accountTitle.trim()
        : customer.name.trim();
    final initials = titleText.isEmpty
        ? '?'
        : titleText.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final statusColor = _getStatusColor(customer.status);
    final statusText = customer.status.trim().isNotEmpty ? customer.status.trim() : 'Active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TiltTapCard(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      Colors.white.withValues(alpha: 0.68),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.3,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Hero(
                      tag: 'avatar-${customer.accountNumber}',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getAvatarGradient(customer.accountType),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${customer.maskedAccountNumber}  •  ${customer.maskedPhone}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.2), width: 0.8),
                                ),
                                child: Text(
                                  customer.accountType,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
