import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/floating_navigation_bar.dart';
import 'dashboard_screen.dart';
import '../../customers/views/search_results_screen.dart';
import '../../customers/views/add_customer_screen.dart';
import 'activity_log_screen.dart';
import '../../profile/views/edit_profile_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  final AppUser currentUser;
  final int initialIndex;

  const MainNavigationScaffold({
    super.key,
    required this.currentUser,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddCustomer() async {
    await push3D(
      context,
      AddCustomerScreen(currentUser: widget.currentUser),
    );
    // Refresh current view state if on Dashboard or Customers tab
    setState(() {});
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(currentUser: widget.currentUser);
      case 1:
        return SearchResultsScreen(
          query: '',
          searchField: 'All',
          currentUser: widget.currentUser,
        );
      case 2:
        return ActivityLogScreen(currentUser: widget.currentUser);
      case 3:
        return EditProfileScreen(currentUser: widget.currentUser);
      default:
        return DashboardScreen(currentUser: widget.currentUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: FloatingNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onAddTap: _openAddCustomer,
      ),
    );
  }
}
