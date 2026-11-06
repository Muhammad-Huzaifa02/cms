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

/// Customer Details and Edit Screen.
/// Formatted in the exact standardized sequence:
/// 1. Account Title
/// 2. Account Number
/// 3. IBAN No
/// 4. Account Type
/// 5. Account Status
/// 6. CNIC
/// 7. Phone Number
/// 8. Email
/// 9. Address
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  final AppUser currentUser;
  final bool isEditable;
  final bool allowEditAction;
  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.currentUser,
    this.isEditable = false,
    this.allowEditAction = false,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  static const _statusOptions = ['Active', 'Inactive', 'Dormant', 'Blocked'];

  late TextEditingController _accountTitleCtrl;
  late final TextEditingController _accountNumberDisplayCtrl;
  late TextEditingController _ibnCtrl;
  late final TextEditingController _accountTypeDisplayCtrl;
  late TextEditingController _cnicCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _accountTitleCtrl = TextEditingController(text: c.accountTitle);
    _accountNumberDisplayCtrl = TextEditingController(text: c.accountNumber);
    _ibnCtrl = TextEditingController(text: c.ibnNo);
    _accountTypeDisplayCtrl = TextEditingController(text: c.accountType);
    _cnicCtrl = TextEditingController(text: c.cnic);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email ?? '');
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _status = _statusOptions.contains(c.status) ? c.status : _statusOptions.first;
  }

  @override
  void dispose() {
    _accountTitleCtrl.dispose();
    _accountNumberDisplayCtrl.dispose();
    _ibnCtrl.dispose();
    _accountTypeDisplayCtrl.dispose();
    _cnicCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.isEditable && widget.currentUser.can('edit');
  bool get _canDelete => widget.isEditable && widget.currentUser.can('delete');

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = Customer(
        accountNumber: widget.customer.accountNumber,
        name: _accountTitleCtrl.text.trim(),
        accountTitle: _accountTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: widget.customer.accountType,
        ibnNo: _ibnCtrl.text.trim().toUpperCase(),
        status: _status,
        gender: widget.customer.gender,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        dateOpened: widget.customer.dateOpened,
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        notes: widget.customer.notes ?? '',
        createdBy: widget.customer.createdBy,
        createdAt: widget.customer.createdAt,
        updatedBy: widget.currentUser.uid,
      );
      // Duplicate checks only fire for phone/CNIC that actually changed —
      // see CustomerService.updateCustomer's doc comment.
      await _service.updateCustomer(
        updated,
        widget.currentUser,
        originalPhone: widget.customer.phone,
        originalCnic: widget.customer.cnic,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteCustomer(widget.customer.accountNumber, widget.currentUser);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.isEditable ? 'Edit Customer' : 'Customer Details'),
        actions: [
          if (!widget.isEditable && widget.allowEditAction && widget.currentUser.can('edit'))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Customer',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(
                      customer: widget.customer,
                      currentUser: widget.currentUser,
                      isEditable: true,
                      allowEditAction: true,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
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
                  readOnly: !_canEdit,
                  validator: Validators.accountTitle,
                ),
                const SizedBox(height: 16),
                // 2. Account Number
                AccountField(
                  label: 'Account Number',
                  controller: _accountNumberDisplayCtrl,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                // 3. IBAN No
                AccountField(
                  label: 'IBAN No.',
                  controller: _ibnCtrl,
                  readOnly: !_canEdit,
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
                // 4. Account Type
                AccountField(
                  label: 'Account Type',
                  controller: _accountTypeDisplayCtrl,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                // 5. Account Status
                const Text('Account Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                _dropdown(
                  value: _status,
                  options: _statusOptions,
                  enabled: _canEdit,
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),
                // 6. CNIC
                AccountField(
                  label: 'CNIC',
                  controller: _cnicCtrl,
                  readOnly: !_canEdit,
                  validator: Validators.cnic,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                ),
                const SizedBox(height: 16),
                // 7. Phone Number
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  readOnly: !_canEdit,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                ),
                const SizedBox(height: 16),
                // 8. Email
                AccountField(
                  label: 'Email',
                  controller: _emailCtrl,
                  readOnly: !_canEdit,
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
                  label: 'Address',
                  controller: _addressCtrl,
                  readOnly: !_canEdit,
                ),
              ],
            ),
            if (_error != null) FeedbackText(_error!, isError: true),
            const SizedBox(height: 18),
            if (_canEdit) PrimaryButton(label: 'Save Changes', loading: _saving, onPressed: _save),
            if (_canDelete)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                  child: TextButton(
                    onPressed: _confirmDelete,
                    child: const Text('Delete this record', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> options,
    required bool enabled,
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
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
