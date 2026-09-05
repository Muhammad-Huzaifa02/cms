import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/perspective_page_route.dart';
import '../../../core/widgets/tilt_tap_card.dart';
import '../../../core/widgets/fade_in_slide.dart';
import 'customer_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final AppUser currentUser;
  const SearchResultsScreen({super.key, required this.query, required this.currentUser});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _service = CustomerService();
  late Future<List<Customer>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.search(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('"${widget.query}"')),
      body: FutureBuilder<List<Customer>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brand));
          }
          final results = snap.data ?? [];
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.muted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No match found for that search.',
                    style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return FadeInSlide(
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('${results.length} match${results.length == 1 ? '' : 'es'}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                );
              }
              final c = results[i - 1];
              return FadeInSlide(
                delay: Duration(milliseconds: 50 * i),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (i * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(0.2 * (1 - value))
                        // ignore: deprecated_member_use
                        ..scale(0.9 + (0.1 * value), 0.9 + (0.1 * value), 1.0),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: TiltTapCard(
                    onTap: () => push3D(context, CustomerDetailScreen(customer: c, currentUser: widget.currentUser)),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: Hero(
                          tag: 'avatar-${c.accountNumber}',
                          child: CircleAvatar(
                            backgroundColor: AppColors.brand,
                            child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('${c.maskedAccountNumber} · ${c.accountType}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
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
