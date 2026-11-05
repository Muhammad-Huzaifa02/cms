import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/account_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/feedback_text.dart';

/// Same three-section structure as Customer Details (Customer / Contact /
/// Account Information) so creating and viewing a customer feel like the
/// same screen, built from the same shared components. All validation and
/// duplicate-checking is unchanged — this is a layout/consistency pass,
/// not a business-logic change.
class AddCustomerScreen extends StatefulWidget {
  final AppUser currentUser;
  const AddCustomerScreen({super.key, required this.currentUser});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  static const _accountCategories = [
    'Current Accounts',
    'Savings Accounts',
    'Special Savings Accounts',
    'Asaan Accounts',
    'Digital Accounts',
    'Roshan Resident Accounts',
    'Home Remittance Accounts',
    'Meezan Smart Accounts',
    'Business / Entity Accounts',
  ];

  static const Map<String, List<String>> _accountTypesByCategory = {
    'Current Accounts': [
      'Meezan Rupee Current Account',
      'Meezan Dollar Current Account',
      'Meezan Euro Current Account',
      'Meezan GBP Current Account',
      'Meezan Express Current Account',
    ],
    'Savings Accounts': [
      'Meezan Rupee Savings Account',
      'Meezan Dollar Savings Account',
      'Meezan Euro Savings Account',
      'Meezan GBP Savings Account',
      'Meezan Express Savings Account',
    ],
    'Special Savings Accounts': [
      'Meezan Bachat Account',
      'Meezan Labbaik Saving Aasaan',
      'Meezan Senior Citizen Account',
      'Meezan Plus Account',
      'Meezan Teens Club Account',
      'Meezan Kids Club Account',
    ],
    'Asaan Accounts': [
      'Meezan Asaan Current Account',
      'Meezan Asaan Savings Account',
    ],
    'Digital Accounts': [
      'Digital Student Account',
      'Digital Asaan Account',
      'Digital Freelancer Account',
    ],
    'Roshan Resident Accounts': [
      'Meezan Roshan Resident Current Account',
      'Meezan Roshan Resident Savings Account',
    ],
    'Home Remittance Accounts': [
      'Sohni Dharti Remittance Account',
      'Smart Remittance Wallet',
      'Roshan Digital Account',
    ],
    'Meezan Smart Accounts': [
      'Smart Wallet Current',
      'Smart Wallet Savings',
      'Smart Asaan Mobile Account',
    ],
    'Business / Entity Accounts': [
      'Business / Entity Current Account',
      'Business / Entity Savings Account',
      'Karobari Munafa Account',
      'Karobari Munafa Account Plus',
    ],
  };

  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _statusOptions = ['Active', 'Inactive', 'Dormant', 'Blocked'];

  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  final _nameCtrl = TextEditingController();
  final _accountTitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ibnCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'Male';
  String _status = 'Active';
  String _accountCategory = _accountCategories.first;
  String _accountType = _accountTypesByCategory[_accountCategories.first]!.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cnicCtrl.dispose();
    _accountCtrl.dispose();
    _ibnCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final customer = Customer(
        accountNumber: _accountCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        accountTitle: _accountTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: _accountType,
        ibnNo: _ibnCtrl.text.trim().toUpperCase(),
        status: _status,
        gender: _gender,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        createdBy: widget.currentUser.uid,
        updatedBy: widget.currentUser.uid,
      );
      await _service.addCustomer(customer, widget.currentUser);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Add Customer')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SectionCard(
              title: 'Customer Information',
              children: [
                AccountField(label: 'Full Name', controller: _nameCtrl, validator: Validators.requiredName),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Account Title',
                  controller: _accountTitleCtrl,
                  hintText: 'e.g. Ali Traders',
                  validator: Validators.accountTitle,
                ),
                const SizedBox(height: 16),
                const Text('Gender', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                _accountDropdown(
                  value: _gender,
                  options: _genderOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Contact Information',
              children: [
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  hintText: '03001234567',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Email Address (optional)',
                  controller: _emailCtrl,
                  hintText: 'customer@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    final trimmed = (val ?? '').trim();
                    if (trimmed.isNotEmpty && (!trimmed.contains('@') || !trimmed.contains('.'))) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AccountField(label: 'Address (optional)', controller: _addressCtrl),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Account Information',
              children: [
                AccountField(
                  label: 'CNIC',
                  controller: _cnicCtrl,
                  hintText: '3520212345671',
                  keyboardType: TextInputType.number,
                  validator: Validators.cnic,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Account Number',
                  controller: _accountCtrl,
                  hintText: '12345678901234',
                  keyboardType: TextInputType.number,
                  validator: Validators.accountNumber,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'IBN No.',
                  controller: _ibnCtrl,
                  hintText: 'e.g. PK36MEZN0001234567890123',
                  validator: Validators.ibnNo,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        )),
                    LengthLimitingTextInputFormatter(24),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Account Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                _accountDropdown(
                  value: _status,
                  options: _statusOptions,
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Account Category', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                _accountDropdown(
                  value: _accountCategory,
                  options: _accountCategories,
                  onChanged: (category) {
                    if (category == null) return;
                    setState(() {
                      _accountCategory = category;
                      _accountType = _accountTypesByCategory[category]!.first;
                    });
                  },
                ),
                const SizedBox(height: 14),
                const Text('Account Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                _accountDropdown(
                  value: _accountType,
                  options: _accountTypesByCategory[_accountCategory]!,
                  onChanged: (type) {
                    if (type != null) setState(() => _accountType = type);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Notes',
              children: [
                AccountField(label: 'Notes (optional)', controller: _notesCtrl),
              ],
            ),
            if (_error != null) FeedbackText(_error!, isError: true),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Save Customer', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _accountDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: const InputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 360,
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
