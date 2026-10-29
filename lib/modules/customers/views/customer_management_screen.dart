import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/favorite_service.dart';
import 'customer_detail_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  const CustomerManagementScreen({super.key, required this.currentUser});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final _customers = CustomerService();
  final _favorites = FavoriteService();
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(String customerId, bool favorite) async {
    try {
      await _favorites.setFavorite(uid: widget.currentUser.uid, customerId: customerId, favorite: !favorite);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorite: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.can('view')) {
      return const Scaffold(body: Center(child: Text('You do not have permission to view customers.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Management')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search customers',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    }),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: _customers.allCustomers(),
            builder: (context, customerSnapshot) {
              if (customerSnapshot.hasError) {
                return const Center(child: Text('Unable to load customers. Check access and connection.'));
              }
              if (!customerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final customers = customerSnapshot.data!.where((customer) {
                if (_query.isEmpty) return true;
                return customer.name.toLowerCase().contains(_query) ||
                    customer.accountTitle.toLowerCase().contains(_query) ||
                    customer.accountNumber.contains(_query) ||
                    customer.phone.contains(_query) ||
                    customer.cnic.contains(_query) ||
                    customer.ibnNo.toLowerCase().contains(_query);
              }).toList();
              if (customers.isEmpty) {
                return Center(child: Text(_query.isEmpty ? 'No customers yet.' : 'No matching customers.'));
              }
              return StreamBuilder<Set<String>>(
                stream: _favorites.watchIds(widget.currentUser.uid),
                builder: (context, favoriteSnapshot) {
                  final favoriteIds = favoriteSnapshot.data ?? <String>{};
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final favorite = favoriteIds.contains(customer.accountNumber);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.brandSoft,
                            foregroundColor: AppColors.brand,
                            child: Text(customer.name.isEmpty ? '?' : customer.name[0].toUpperCase()),
                          ),
                          title: Text(customer.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${customer.accountTitle}\n${customer.maskedAccountNumber}', maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          isThreeLine: false,
                          onTap: () => push3D(context,
                              CustomerDetailScreen(customer: customer, currentUser: widget.currentUser)),
                          trailing: IconButton(
                            tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
                            onPressed: () => _toggleFavorite(customer.accountNumber, favorite),
                            icon: Icon(favorite ? Icons.star : Icons.star_border,
                                color: favorite ? AppColors.gold : AppColors.muted),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
