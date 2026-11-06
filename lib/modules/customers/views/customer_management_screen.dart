import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const _pageSize = 50;

  final _customers = CustomerService();
  final _favorites = FavoriteService();
  final _search = TextEditingController();
  final _listController = ScrollController();
  late final Stream<Set<String>> _favoriteStream = _favorites.watchIds(widget.currentUser.uid);

  final List<Customer> _loadedCustomers = [];
  Timer? _searchDebounce;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  Future<List<Customer>>? _favoriteCustomersFuture;
  String _favoriteCustomersKey = '';
  String _query = '';
  String? _loadError;
  int _requestGeneration = 0;
  bool _favoritesOnly = false;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_onListScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onListScroll() {
    if (_listController.position.extentAfter < 400) _loadPage();
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;
    final generation = reset ? ++_requestGeneration : _requestGeneration;
    final cursor = reset ? null : _lastDocument;
    setState(() {
      if (reset) {
        _initialLoading = true;
        _loadError = null;
        _lastDocument = null;
        _hasMore = true;
        _loadingMore = false;
        _loadedCustomers.clear();
      } else {
        _loadingMore = true;
      }
    });

    try {
      final page = await _customers.managementPage(
        query: _query,
        startAfter: cursor,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadedCustomers.addAll(page.customers);
        _lastDocument = page.lastDocument;
        _hasMore = page.hasMore;
        _initialLoading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadError = error.toString();
        _initialLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final query = value.trim().toLowerCase();
      if (_query == query) return;
      setState(() => _query = query);
      _loadPage(reset: true);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _search.clear();
    if (_query.isEmpty) return;
    setState(() => _query = '');
    _loadPage(reset: true);
  }

  Future<void> _toggleFavorite(String customerId, bool isFavorite) async {
    try {
      await _favorites.setFavorite(
        uid: widget.currentUser.uid,
        customerId: customerId,
        favorite: !isFavorite,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update favorite: ${error.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<List<Customer>> _favoriteCustomers(Set<String> ids) {
    final key = (ids.toList()..sort()).join(',');
    if (_favoriteCustomersFuture == null || key != _favoriteCustomersKey) {
      _favoriteCustomersKey = key;
      final alreadyLoaded = _loadedCustomers
          .where((customer) => ids.contains(customer.accountNumber))
          .toList();
      final loadedIds = alreadyLoaded.map((customer) => customer.accountNumber).toSet();
      final missingIds = ids.difference(loadedIds).toList();
      _favoriteCustomersFuture = _customers.customersByIds(missingIds).then((missing) {
        final customers = [...alreadyLoaded, ...missing];
        customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return customers;
      });
    }
    return _favoriteCustomersFuture!;
  }

  Widget _customerList(List<Customer> customers, Set<String> favoriteIds, {required bool canLoadMore}) {
    if (_initialLoading && customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null && customers.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Unable to load customers. Check access and connection.'),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _loadPage(reset: true), child: const Text('Try again')),
        ]),
      );
    }
    if (customers.isEmpty) {
      if (canLoadMore && _hasMore && _query.isNotEmpty) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No matches on this page.'),
            TextButton(onPressed: _loadPage, child: const Text('Search more customers')),
          ]),
        );
      }
      return Center(child: Text(_query.isEmpty ? 'No customers yet.' : 'No matching customers.'));
    }

    final showFooter = canLoadMore && _hasMore;
    return ListView.builder(
      controller: canLoadMore ? _listController : null,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: customers.length + (showFooter ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == customers.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(onPressed: _loadPage, child: const Text('Load more customers')),
            ),
          );
        }
        final customer = customers[index];
        final favorite = favoriteIds.contains(customer.accountNumber);
        final titleText = customer.accountTitle.trim().isNotEmpty
            ? customer.accountTitle.trim()
            : customer.name.trim();
        final initials = titleText.isEmpty
            ? '?'
            : titleText.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
        final statusColor = _getStatusColor(customer.status);
        final statusText = customer.status.trim().isNotEmpty ? customer.status.trim() : 'Active';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4ECE8), width: 1.1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _getAvatarGradient(customer.accountType),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${customer.maskedAccountNumber} • ${customer.accountType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ph: ${customer.maskedPhone}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => push3D(
              context,
              CustomerDetailScreen(
                customer: customer,
                currentUser: widget.currentUser,
                allowEditAction: true,
              ),
            ),
            trailing: IconButton(
              tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
              onPressed: () => _toggleFavorite(customer.accountNumber, favorite),
              icon: Icon(
                favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: favorite ? AppColors.gold : AppColors.muted,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

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
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search customers',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, children: [
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
            ]),
          ),
        ),
        Expanded(
          child: StreamBuilder<Set<String>>(
            stream: _favoriteStream,
            builder: (context, favoriteSnapshot) {
              final favoriteIds = favoriteSnapshot.data ?? <String>{};
              if (!_favoritesOnly) {
                return _customerList(_loadedCustomers, favoriteIds, canLoadMore: true);
              }
              return FutureBuilder<List<Customer>>(
                future: _favoriteCustomers(favoriteIds),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final query = _query;
                  final matching = snapshot.data!.where((customer) {
                    if (query.isEmpty) return true;
                    return customer.name.toLowerCase().contains(query) ||
                        customer.accountTitle.toLowerCase().contains(query) ||
                        customer.accountNumber.contains(query) ||
                        customer.phone.contains(query) ||
                        customer.cnic.contains(query) ||
                        customer.ibnNo.toLowerCase().contains(query);
                  }).toList();
                  if (matching.isEmpty) {
                    return Center(
                      child: Text(query.isEmpty
                          ? 'No favorite customers yet.'
                          : 'No favorite customers match your search.'),
                    );
                  }
                  return _customerList(matching, favoriteIds, canLoadMore: false);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
