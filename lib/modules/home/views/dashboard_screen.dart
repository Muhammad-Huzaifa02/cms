import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/export_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/tilt_tap_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
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
  bool _exporting = false;

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
    push3D(context, SearchResultsScreen(query: query.trim(), currentUser: widget.currentUser));
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = true);
    try {
      final customers = await _customerService.recentCustomers(limit: 5000).first;
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
      body: CustomScrollView(
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
                      padding: const EdgeInsets.fromLTRB(22, 50, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Welcome back', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5)),
                                const SizedBox(height: 2),
                                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
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
              if (_exporting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 26),
                  tooltip: 'Logout & Exit',
                  onPressed: _logoutAndExit,
                ),
              const SizedBox(width: 8),
            ],
          ),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0015)
                          ..rotateX(0.25 * (1 - value))
                          // ignore: deprecated_member_use
                          ..scale(0.9 + (0.1 * value), 0.9 + (0.1 * value), 1.0),
                        child: child,
                      );
                    },
                    child: Material(
                      elevation: 16,
                      shadowColor: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: _runSearch,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search name, CNIC, phone, account…',
                          hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
                          prefixIcon: const Icon(Icons.search, size: 24, color: AppColors.brand),
                          suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, size: 22), onPressed: () => _runSearch(_searchCtrl.text)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<Customer>>(
            stream: _customerService.recentCustomers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  sliver: ShimmerLoading(count: 6),
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
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12, top: 10),
                          child: Text('RECENT CUSTOMERS', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: AppColors.muted, fontWeight: FontWeight.bold)),
                        );
                      }
                      final c = customers[index - 1];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 80)),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(0.15 * (1 - value))
                                ..rotateX(0.1 * (1 - value))
                                // ignore: deprecated_member_use
                                ..translate(40 * (1 - value), 0.0, 0.0),
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
      floatingActionButton: user.can('add')
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
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

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TiltTapCard(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Hero(
              tag: 'avatar-${customer.accountNumber}',
              child: CircleAvatar(
                backgroundColor: AppColors.brand,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${customer.maskedAccountNumber} · ${customer.accountType}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}
