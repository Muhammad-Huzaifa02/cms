import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/account_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/feedback_text.dart';

/// Add Customer Screen.
/// Formatted in the exact standardized sequence:
/// 1. Account Title
/// 2. Account Number
/// 3. IBAN No
/// 4. Account Type (Account Category + Account Type)
/// 5. Account Status
/// 6. CNIC
/// 7. Phone Number
/// 8. Email
/// 9. Address
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

  static const _statusOptions = ['Active', 'Inactive', 'Dormant', 'Blocked'];

  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  final _accountTitleCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ibnCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _status = 'Active';
  String _accountCategory = _accountCategories.first;
  String _accountType = _accountTypesByCategory[_accountCategories.first]!.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _accountTitleCtrl.dispose();
    _accountCtrl.dispose();
    _ibnCtrl.dispose();
    _cnicCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final customer = Customer(
        accountNumber: _accountCtrl.text.trim(),
        name: _accountTitleCtrl.text.trim(),
        accountTitle: _accountTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: _accountType,
        ibnNo: _ibnCtrl.text.trim().toUpperCase(),
        status: _status,
        gender: null,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        notes: null,
        createdBy: widget.currentUser.uid,
        updatedBy: widget.currentUser.uid,
      );
      await _service.addCustomer(customer, widget.currentUser);
      if (!mounted) return;

      // Offer immediate automated notification dispatch (SMS / WhatsApp)
      final phone = customer.phone;
      final welcomeMsg = CustomerNotificationService.buildWelcomeMessage(
        accountTitle: customer.accountTitle,
        accountNumber: customer.accountNumber,
        accountType: customer.accountType,
        ibnNo: customer.ibnNo,
      );

      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
              SizedBox(width: 10),
              Text('Customer Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer record created. Would you like to send an automated confirmation message to $phone?',
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  welcomeMsg,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Skip'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF25D366)),
              label: const Text('Send WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final waPhone = CustomerNotificationService.normalizeWhatsAppPhone(phone);
                Clipboard.setData(ClipboardData(text: '$welcomeMsg (Target: +$waPhone)'));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF075E54),
                    content: Text('WhatsApp receipt copied for +$waPhone.'),
                  ),
                );
              },
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.sms_rounded, size: 16),
              label: const Text('Send SMS', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: welcomeMsg));
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.brand,
                    content: Text('SMS receipt copied for $phone.'),
                  ),
                );
              },
            ),
          ],
        ),
      );

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
              title: 'Customer Details',
              children: [
                // 1. Account Title
                AccountField(
                  label: 'Account Title',
                  controller: _accountTitleCtrl,
                  hintText: 'e.g. Ali Traders',
                  validator: Validators.accountTitle,
                ),
                const SizedBox(height: 16),
                // 2. Account Number
                AccountField(
                  label: 'Account Number',
                  controller: _accountCtrl,
                  hintText: '12345678901234',
                  keyboardType: TextInputType.number,
                  validator: Validators.accountNumber,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                ),
                const SizedBox(height: 16),
                // 3. IBAN No
                AccountField(
                  label: 'IBAN No.',
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
                // 4. Account Type (Category + Type)
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
                const SizedBox(height: 16),
                // 5. Account Status
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
                // 6. CNIC
                AccountField(
                  label: 'CNIC',
                  controller: _cnicCtrl,
                  hintText: '3520212345671',
                  keyboardType: TextInputType.number,
                  validator: Validators.cnic,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                ),
                const SizedBox(height: 16),
                // 7. Phone Number
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  hintText: '03001234567',
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                ),
                const SizedBox(height: 16),
                // 8. Email
                AccountField(
                  label: 'Email (optional)',
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
                // 9. Address
                AccountField(
                  label: 'Address (optional)',
                  controller: _addressCtrl,
                ),
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
