import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../core/theme/app_theme.dart';
import 'search_results_screen.dart';

/// Implements the "Search Customer By" flow: the user must pick exactly
/// ONE field (Account Title / Account Number / Phone / CNIC) before
/// entering a value, and the resulting search only ever queries that one
/// field — never several at once. See CustomerService's
/// searchBy*/searchByField methods for the actual query isolation.
class SearchCustomerScreen extends StatefulWidget {
  final AppUser currentUser;
  const SearchCustomerScreen({super.key, required this.currentUser});

  @override
  State<SearchCustomerScreen> createState() => _SearchCustomerScreenState();
}

class _SearchCustomerScreenState extends State<SearchCustomerScreen> {
  CustomerSearchField? _selectedField;
  final _valueCtrl = TextEditingController();
  String? _error;

  void _selectField(CustomerSearchField? field) {
    setState(() {
      _selectedField = field;
      _valueCtrl.clear();
      _error = null;
    });
  }

  void _submit() {
    final field = _selectedField;
    if (field == null) return;
    final value = _valueCtrl.text.trim();

    if (field.isFreeText) {
      if (value.isEmpty) {
        setState(() => _error = 'Enter a value to search.');
        return;
      }
      // Title search matches on word prefixes of 2+ letters (see
      // Customer.buildAccountTitleSearchWords), so a lone letter could
      // never match anything and would just read as "no customers".
      if (!value.split(RegExp(r'\s+')).any((w) => w.length >= 2)) {
        setState(() => _error = 'Enter at least 2 letters of the account title.');
        return;
      }
    } else {
      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length != 4) {
        setState(() => _error = 'Please enter exactly 4 digits.');
        return;
      }
    }

    setState(() => _error = null);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchResultsScreen(
        searchField: field,
        query: value,
        currentUser: widget.currentUser,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final field = _selectedField;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Customer By')),
      body: SafeArea(child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (field == null) ...[
              const Text(
                'Choose exactly one field to search by. Results will only '
                'match that field — not any other customer information.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ...CustomerSearchField.values.map((f) => _FieldOption(
                    field: f,
                    onTap: () => _selectField(f),
                  )),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt, size: 16, color: AppColors.brand),
                          const SizedBox(width: 8),
                          Text('Search By: ${field.label}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _selectField(null),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(field.inputHint, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _valueCtrl,
                autofocus: true,
                keyboardType: field.isFreeText ? TextInputType.text : TextInputType.number,
                inputFormatters: field.isFreeText
                    ? null
                    : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: field.isFreeText ? 'e.g. Muhammad Huzaifa' : 'e.g. 4567',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Search Customer'),
                ),
              ),
            ],
          ],
        )),
      ))),
    );
  }
}

class _FieldOption extends StatelessWidget {
  final CustomerSearchField field;
  final VoidCallback onTap;
  const _FieldOption({required this.field, required this.onTap});

  IconData get _icon => switch (field) {
        CustomerSearchField.accountTitle => Icons.badge_outlined,
        CustomerSearchField.accountNumber => Icons.numbers,
        CustomerSearchField.phone => Icons.phone_outlined,
        CustomerSearchField.cnic => Icons.credit_card_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(_icon, color: AppColors.brand),
        title: Text(field.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}
