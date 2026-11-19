import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../../../core/widgets/aurora_header_background.dart';
import '../../../core/widgets/shimmer_sheen_badge.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _exporting = false;
  bool _showFab = true;
  late Stream<List<Customer>> _recentCustomersStream = _customerService.recentCustomers();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInAppUpdate());
  }

  void _onScroll() {
    final hide = _scrollController.hasClients &&
        _scrollController.offset > 80 &&
        _scrollController.position.userScrollDirection == ScrollDirection.reverse;
    final show = _scrollController.hasClients &&
        (_scrollController.offset <= 80 ||
            _scrollController.position.userScrollDirection == ScrollDirection.forward);
    if (hide && _showFab) {
      setState(() => _showFab = false);
    } else if (show && !_showFab) {
      setState(() => _showFab = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _showProfileSheet(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xF20F1F1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.isAdmin
                          ? const LinearGradient(colors: [Color(0xFFD4AF37), AppColors.gold])
                          : const LinearGradient(colors: [AppColors.brandLight, AppColors.brand]),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.trim().isNotEmpty
                          ? user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? user.phone ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.isAdmin ? AppColors.gold.withValues(alpha: 0.2) : AppColors.brandLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: user.isAdmin ? AppColors.gold.withValues(alpha: 0.6) : AppColors.brandLight.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            user.isAdmin ? 'ADMINISTRATOR' : 'BANKING STAFF',
                            style: TextStyle(
                              color: user.isAdmin ? AppColors.gold : Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: Colors.white),
                title: const Text('Edit Profile & Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // close drawer as well
                  push3D(context, EditProfileScreen(currentUser: user));
                },
              ),
              if (user.isAdmin)
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.gold),
                  title: const Text('Sync Search Index', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    _runBackfill();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFFDA4AF)),
                title: const Text('Sign Out', style: TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.w700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  _confirmSignOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);

    // Show Cryptographic Vault Sealing modal dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CryptographicVaultSealingDialog(),
    );

    try {
      final customers = await _customerService.recentCustomers(limit: 5000).first;
      final file = format == 'excel'
          ? await _exportService.exportToExcel(customers, widget.currentUser)
          : format == 'pdf'
              ? await _exportService.exportToPdf(customers, widget.currentUser)
              : await _exportService.exportToJsonBackup(customers, widget.currentUser);
      
      final shaDigest = await _exportService.calculateFileSha256(file);
      final shortSha = shaDigest.length >= 12 ? shaDigest.substring(0, 12) : shaDigest;

      if (!mounted) return;
      // Close sealing dialog
      Navigator.of(context, rootNavigator: true).pop();

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

      await _exportService.shareFile(
        file,
        subject: format == 'json'
            ? 'CMS Database Backup Vault (SHA256: $shortSha)'
            : 'CMS Customer Export (SHA256: $shortSha)',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
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
        width: (MediaQuery.of(context).size.width * 0.82).clamp(290.0, 335.0),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 0, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: AppColors.brandDeep.withValues(alpha: 0.40),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Stack(
                  children: [
                    // Base obsidian/dark acrylic glass background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xEB161B19),
                              Color(0xF20F1F1A),
                              Color(0xEB141A17),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Atmospheric brand ambient glow orbs
                    Positioned(
                      top: -30,
                      left: -20,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.brandLight.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content layout
                    Column(
                      children: [
                        // Top Workspace Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          child: Row(
                            children: [
                              // Circular Brand Badge
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.brandLight,
                                      AppColors.brand,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandLight.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'CUSTOMER MANAGEMENT SYSTEM',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 1.5),
                                    Text(
                                      'CMS • Branch Workspace',
                                      style: TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Circular Floating Close Button (<)
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Color(0xFF1F2937),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Search Pill
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(19),
                            onTap: () {
                              Navigator.pop(context);
                              _openSearch();
                            },
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(19),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 17,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Search customer...',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.50),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.40),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Navigation Items List
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: [
                              // ── OVERVIEW ──
                              const _VertixSectionHeader('OVERVIEW'),
                              _VertixActiveStadiumTile(
                                icon: Icons.dashboard_rounded,
                                title: 'Dashboard',
                                onTap: () => Navigator.pop(context),
                              ),
                              if (user.can('view'))
                                _VertixNavItem(
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
                                const _VertixSectionHeader('ADMINISTRATION'),
                                _VertixNavItem(
                                  icon: Icons.badge_outlined,
                                  title: 'Staff Management',
                                  subtitle: 'Roles, accounts & permissions',
                                  onTap: () {
                                    Navigator.pop(context);
                                    push3D(context, StaffManagementScreen(currentUser: user));
                                  },
                                ),
                                _VertixNavItem(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Activity Audit Log',
                                  subtitle: 'Security & compliance trail',
                                  onTap: () {
                                    Navigator.pop(context);
                                    push3D(context, ActivityLogScreen(currentUser: user));
                                  },
                                ),

                                const SizedBox(height: 6),
                                const _VertixSectionHeader('DATA & EXPORT'),
                                _VertixNavItem(
                                  icon: Icons.table_chart_outlined,
                                  iconColor: const Color(0xFF34D399),
                                  title: 'Export to Excel (.xlsx)',
                                  subtitle: 'Branch customer spreadsheet',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _export('excel');
                                  },
                                ),
                                _VertixNavItem(
                                  icon: Icons.picture_as_pdf_outlined,
                                  iconColor: const Color(0xFFF87171),
                                  title: 'Export to PDF Document',
                                  subtitle: 'Executive audit digest',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _export('pdf');
                                  },
                                ),
                                _VertixNavItem(
                                  icon: Icons.backup_outlined,
                                  iconColor: const Color(0xFF60A5FA),
                                  title: 'Backup Database (.json)',
                                  subtitle: 'Full-fidelity recovery snapshot',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _export('json');
                                  },
                                ),

                                const SizedBox(height: 6),
                                const _VertixSectionHeader('SYSTEM MAINTENANCE'),
                                _VertixNavItem(
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

                        // Bottom Profile Footer
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 14),
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                          child: _VertixUserProfileTile(
                            user: user,
                            onTap: () => _showProfileSheet(context, user),
                          ),
                        ),
                        // Glowing Sign Out Button & Version
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                          child: Column(
                            children: [
                              _ModernGlassSignOutButton(
                                onTap: () {
                                  Navigator.pop(context);
                                  _confirmSignOut();
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 11.5,
                                    color: AppColors.gold.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'CMS v1.0.0 • Secured Banking Portal',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.60),
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
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
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
                background: AuroraHeaderBackground(
                  height: 200,
                  child: Padding(
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
                      final delay = (index * 40).clamp(0, 360);
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 320 + delay),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) {
                          return Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 16),
                              child: child,
                            ),
                          );
                        },
                        child: _CustomerTile(
                          customer: c,
                          onTap: () => push3D(context, CustomerDetailScreen(customer: c, currentUser: user)),
                        ),
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
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _showFab ? Offset.zero : const Offset(0, 2),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                scale: _showFab ? 1.0 : 0.0,
                child: FloatingActionButton(
                  elevation: 8,
                  backgroundColor: AppColors.gold,
                  onPressed: () => push3D(context, AddCustomerScreen(currentUser: user)),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
    );
  }

}

class _VertixSectionHeader extends StatelessWidget {
  final String title;
  const _VertixSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.42),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _VertixActiveStadiumTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _VertixActiveStadiumTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppColors.brandLight.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VertixNavItem extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _VertixNavItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  State<_VertixNavItem> createState() => _VertixNavItemState();
}

class _VertixNavItemState extends State<_VertixNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ?? Colors.white.withValues(alpha: 0.85);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: _isHovered ? Colors.white : effectiveIconColor,
                    ),
                    const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w600,
                              color: _isHovered
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.90),
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 1.5),
                            Text(
                              widget.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: _isHovered
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.white.withValues(alpha: 0.50),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: _isHovered
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
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

class _VertixUserProfileTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _VertixUserProfileTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Avatar with green status dot at bottom-right
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: user.isAdmin
                            ? const LinearGradient(
                                colors: [Color(0xFFD4AF37), AppColors.gold],
                              )
                            : const LinearGradient(
                                colors: [AppColors.brandLight, AppColors.brand],
                              ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.trim().isNotEmpty
                            ? user.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981),
                          border: Border.all(
                            color: const Color(0xFF161B19),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        user.email ?? user.phone ?? 'branch@cms.bank',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ],
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
        duration: const Duration(milliseconds: 180),
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
            width: 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
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
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded, color: Color(0xFFFDA4AF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: 0.2,
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
                              ShimmerSheenBadge(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _BreathingStatusDot(color: statusColor),
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

class _BreathingStatusDot extends StatefulWidget {
  final Color color;
  const _BreathingStatusDot({required this.color});

  @override
  State<_BreathingStatusDot> createState() => _BreathingStatusDotState();
}

class _BreathingStatusDotState extends State<_BreathingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value;
        return Container(
          width: 5.5,
          height: 5.5,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 + (0.5 * t)),
                blurRadius: 2.0 + (3.0 * t),
                spreadRadius: 0.5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CryptographicVaultSealingDialog extends StatefulWidget {
  const _CryptographicVaultSealingDialog();

  @override
  State<_CryptographicVaultSealingDialog> createState() => _CryptographicVaultSealingDialogState();
}

class _CryptographicVaultSealingDialogState extends State<_CryptographicVaultSealingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xF20F1F1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.brandDeep.withValues(alpha: 0.35),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinning cryptographic vault dial
              RotationTransition(
                turns: _spinCtrl,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.brandLight,
                        AppColors.gold,
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0F1F1A),
                      ),
                      child: const Icon(
                        Icons.lock_clock_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Cryptographic Sealing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Computing SHA-256 fingerprint & packaging branch records...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

