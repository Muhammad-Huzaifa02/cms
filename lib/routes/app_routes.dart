import 'package:flutter/material.dart';
import '../core/utils/perspective_page_route.dart';
import '../data/models/user_model.dart';
import '../data/models/customer_model.dart';
import '../modules/authentication/views/login_screen.dart';
import '../modules/authentication/views/create_admin_screen.dart';
import '../modules/home/views/dashboard_screen.dart';
import '../modules/home/views/activity_log_screen.dart';
import '../modules/home/views/staff_management_screen.dart';
import '../modules/home/views/add_staff_screen.dart';
import '../modules/customers/views/add_customer_screen.dart';
import '../modules/customers/views/customer_detail_screen.dart';
import '../modules/customers/views/search_results_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String createAdmin = '/create-admin';
  static const String dashboard = '/dashboard';
  static const String activityLog = '/activity-log';
  static const String staffManagement = '/staff-management';
  static const String addStaff = '/add-staff';
  static const String addCustomer = '/add-customer';
  static const String customerDetail = '/customer-detail';
  static const String searchResults = '/search-results';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return Perspective3DRoute(page: LoginScreen(authService: settings.arguments as dynamic));
      case createAdmin:
        return Perspective3DRoute(page: CreateAdminScreen(authService: settings.arguments as dynamic));
      case dashboard:
        return Perspective3DRoute(page: DashboardScreen(currentUser: settings.arguments as AppUser));
      case activityLog:
        return Perspective3DRoute(page: ActivityLogScreen(currentUser: settings.arguments as AppUser));
      case staffManagement:
        return Perspective3DRoute(page: StaffManagementScreen(currentUser: settings.arguments as AppUser));
      case addStaff:
        return Perspective3DRoute(page: AddStaffScreen(currentUser: settings.arguments as AppUser));
      case addCustomer:
        return Perspective3DRoute(page: AddCustomerScreen(currentUser: settings.arguments as AppUser));
      case customerDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return Perspective3DRoute(
          page: CustomerDetailScreen(
            customer: args['customer'] as Customer,
            currentUser: args['currentUser'] as AppUser,
          ),
        );
      case searchResults:
        final args = settings.arguments as Map<String, dynamic>;
        return Perspective3DRoute(
          page: SearchResultsScreen(
            query: args['query'] as String,
            currentUser: args['currentUser'] as AppUser,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
