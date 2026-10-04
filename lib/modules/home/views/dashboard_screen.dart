import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/customer_growth_chart.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_customers_section.dart';
import '../widgets/search_field_selector.dart';
import '../../customers/views/customer_detail_screen.dart';
import '../../customers/views/add_customer_screen.dart';
import '../../customers/views/search_results_screen.dart';
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
  final _searchCtrl = TextEditingController();

  String _selectedSearchField = 'All';
  GrowthPeriod _selectedPeriod = GrowthPeriod.thisMonth;
  bool _exporting = false;

  late Future<DashboardStats> _statsFuture;
  late Future<List<GrowthPoint>> _growthFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = _customerService.getDashboardStats(widget.currentUser.shopId);
      _growthFuture = _customerService.getGrowthData(
        widget.currentUser.shopId,
        _selectedPeriod,
      );
    });
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit CMS?'),
        content: const Text('This will sign you out and close the application.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Logout & Exit'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _authService.signOut();
      await SystemNavigator.pop();
    }
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) return;
    push3D(
      context,
      SearchResultsScreen(
        query: query.trim(),
        searchField: _selectedSearchField,
        currentUser: widget.currentUser,
      ),
    );
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final customers = await _customerService.recentCustomers(limit: 5000, shopId: widget.currentUser.shopId).first;
      final file = format == 'excel'
          ? await _exportService.exportToExcel(customers, widget.currentUser)
          : await _exportService.exportToPdf(customers, widget.currentUser);
      await _exportService.shareFile(file, subject: 'CMS customer export');
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
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user.email ?? user.phone ?? ''),
              currentAccountPicture: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/icon/app_logo.png', fit: BoxFit.contain),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandDeep, AppColors.brand],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('My account'),
              onTap: () {
                Navigator.pop(context);
                push3D(context, EditProfileScreen(currentUser: user));
              },
            ),
            if (user.isAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Manage staff'),
                onTap: () {
                  Navigator.pop(context);
                  push3D(context, StaffManagementScreen(currentUser: user));
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Activity log'),
                onTap: () {
                  Navigator.pop(context);
                  push3D(context, ActivityLogScreen(currentUser: user));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export to Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _export('excel');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Export to PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _export('pdf');
                },
              ),
            ],
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () async => _refreshData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 138,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.brandDeep,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brandDeep, AppColors.brand],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Opacity(
                          opacity: 0.14,
                          child: Transform.rotate(
                            angle: -0.2,
                            child: Image.asset('assets/icon/app_logo.png', width: 90, height: 90, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + kToolbarHeight - 6, 60, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          user.isAdmin ? 'ADMIN' : 'STAFF',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 0.2),
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                  tooltip: 'Notifications',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications.')),
                    );
                  },
                ),
                if (_exporting)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 24),
                    tooltip: 'Logout & Exit',
                    onPressed: _logoutAndExit,
                  ),
                const SizedBox(width: 8),
              ],
            ),

            // SEARCH BAR & FIELD SELECTOR
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.brand, AppColors.brand],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          elevation: 12,
                          shadowColor: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _searchCtrl,
                            onSubmitted: _runSearch,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search ${_selectedSearchField == 'All' ? 'customers' : _selectedSearchField}…',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
                              prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.brand),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward, size: 22),
                                onPressed: () => _runSearch(_searchCtrl.text),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SearchFieldSelector(
                          selectedField: _selectedSearchField,
                          onFieldSelected: (field) {
                            setState(() => _selectedSearchField = field);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // SUMMARY STATS CARDS GRID
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FutureBuilder<DashboardStats>(
                  future: _statsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: List.generate(4, (_) => const ShimmerCard()),
                      );
                    }

                    if (snap.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Unable to load dashboard data. Please try again.',
                              style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final stats = snap.data ??
                        const DashboardStats(
                          totalCustomers: 0,
                          newThisMonth: 0,
                          activeCustomers: 0,
                          inactiveCustomers: 0,
                        );

                    final growthText = stats.monthlyGrowthPercentage != null
                        ? '${stats.monthlyGrowthPercentage! >= 0 ? '↑' : '↓'} ${stats.monthlyGrowthPercentage!.abs().toStringAsFixed(0)}% vs last month'
                        : '+${stats.newThisMonth} this month';

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        DashboardStatCard(
                          title: 'Total Customers',
                          rawValue: stats.totalCustomers,
                          subtitle: '+${stats.newThisMonth} this month',
                          icon: Icons.people_alt_outlined,
                          accentColor: AppColors.brand,
                          onTap: () {
                            push3D(
                              context,
                              SearchResultsScreen(
                                query: '',
                                searchField: 'All',
                                currentUser: widget.currentUser,
                              ),
                            );
                          },
                        ),
                        DashboardStatCard(
                          title: 'New This Month',
                          rawValue: stats.newThisMonth,
                          subtitle: growthText,
                          icon: Icons.person_add_alt_1_outlined,
                          accentColor: const Color(0xFF10B981),
                        ),
                        DashboardStatCard(
                          title: 'Active Customers',
                          rawValue: stats.activeCustomers,
                          subtitle: 'Primary account base',
                          icon: Icons.check_circle_outline,
                          accentColor: const Color(0xFF6366F1),
                        ),
                        DashboardStatCard(
                          title: 'Inactive Customers',
                          rawValue: stats.inactiveCustomers,
                          subtitle: 'Requires follow-up',
                          icon: Icons.pause_circle_outline,
                          accentColor: const Color(0xFFF59E0B),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // CUSTOMER GROWTH CHART
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FutureBuilder<List<GrowthPoint>>(
                  future: _growthFuture,
                  builder: (context, snap) {
                    final isLoading = snap.connectionState == ConnectionState.waiting;
                    final points = snap.data ?? [];

                    return CustomerGrowthChart(
                      dataPoints: points,
                      selectedPeriod: _selectedPeriod,
                      isLoading: isLoading,
                      onPeriodChanged: (period) {
                        setState(() {
                          _selectedPeriod = period;
                          _growthFuture = _customerService.getGrowthData(
                            widget.currentUser.shopId,
                            period,
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ),

            // QUICK ACTIONS SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: QuickActionsSection(
                  onAddCustomer: () async {
                    await push3D(context, AddCustomerScreen(currentUser: user));
                    _refreshData();
                  },
                  onViewAllCustomers: () {
                    push3D(
                      context,
                      SearchResultsScreen(
                        query: '',
                        searchField: 'All',
                        currentUser: widget.currentUser,
                      ),
                    );
                  },
                  onReports: () {
                    if (user.isAdmin) {
                      _export('excel');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reports export requires Admin permissions.')),
                      );
                    }
                  },
                  onSettings: () {
                    if (user.isAdmin) {
                      push3D(context, StaffManagementScreen(currentUser: user));
                    } else {
                      push3D(context, EditProfileScreen(currentUser: user));
                    }
                  },
                ),
              ),
            ),

            // RECENT CUSTOMERS SECTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                child: StreamBuilder<List<Customer>>(
                  stream: _customerService.recentCustomers(
                    limit: 5,
                    shopId: widget.currentUser.shopId,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const ShimmerLoading(count: 3);
                    }

                    final recentList = snap.data ?? [];

                    return RecentCustomersSection(
                      customers: recentList,
                      onViewAll: () {
                        push3D(
                          context,
                          SearchResultsScreen(
                            query: '',
                            searchField: 'All',
                            currentUser: widget.currentUser,
                          ),
                        );
                      },
                      onCustomerTap: (customer) async {
                        await push3D(
                          context,
                          CustomerDetailScreen(customer: customer, currentUser: user),
                        );
                        _refreshData();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 80, height: 12, color: Colors.grey.shade200),
          const Spacer(),
          Container(width: 60, height: 24, color: Colors.grey.shade200),
          const SizedBox(height: 6),
          Container(width: 100, height: 10, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}
