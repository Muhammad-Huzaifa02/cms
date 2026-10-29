import 'dart:async';
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
  late final Stream<List<Customer>> _customerStream = _customers.allCustomers();
  late final Stream<Set<String>> _favoriteStream = _favorites.watchIds(widget.currentUser.uid);
  Timer? _searchDebounce;
  String _query = '';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
            onChanged: (value) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                if (mounted) setState(() => _query = value.trim().toLowerCase());
              });
            },
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All customers'),
                  selected: !_favoritesOnly,
                  onSelected: (_) => setState(() => _favoritesOnly = false),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.star, size: 18),
                  label: const Text('Favorites'),
                  selected: _favoritesOnly,
                  onSelected: (_) => setState(() => _favoritesOnly = true),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Customer>>(
            stream: _customerStream,
            builder: (context, customerSnapshot) {
              if (customerSnapshot.hasError) {
                return const Center(child: Text('Unable to load customers. Check access and connection.'));
              }
              if (!customerSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final searchedCustomers = customerSnapshot.data!.where((customer) {
                if (_query.isEmpty) return true;
                return customer.name.toLowerCase().contains(_query) ||
                    customer.accountTitle.toLowerCase().contains(_query) ||
                    customer.accountNumber.contains(_query) ||
                    customer.phone.contains(_query) ||
                    customer.cnic.contains(_query) ||
                    customer.ibnNo.toLowerCase().contains(_query);
              }).toList();
              return StreamBuilder<Set<String>>(
                stream: _favoriteStream,
                builder: (context, favoriteSnapshot) {
                  final favoriteIds = favoriteSnapshot.data ?? <String>{};
                  final customers = _favoritesOnly
                      ? searchedCustomers.where((customer) => favoriteIds.contains(customer.accountNumber)).toList()
                      : searchedCustomers;
                  if (customers.isEmpty) {
                    final message = _favoritesOnly
                        ? 'No favorite customers match your search.'
                        : (_query.isEmpty ? 'No customers yet.' : 'No matching customers.');
                    return Center(child: Text(message));
                  }
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
