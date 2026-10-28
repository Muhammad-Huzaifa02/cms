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

/// Organized into three sections — Customer Information, Contact
/// Information, Account Information — matching the fields that actually
/// exist on Customer. No "Activity/Transactions" section: this app has
/// no real transaction data to show, and the activity log is a separate,
/// Admin-only screen rather than something that belongs inline here.
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  final AppUser currentUser;
  const CustomerDetailScreen({super.key, required this.customer, required this.currentUser});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  late TextEditingController _nameCtrl, _accountTitleCtrl, _phoneCtrl, _cnicCtrl, _addressCtrl, _notesCtrl, _ibnCtrl;
  late final TextEditingController _accountTypeDisplayCtrl;
  late final TextEditingController _accountNumberDisplayCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _accountTitleCtrl = TextEditingController(text: c.accountTitle);
    _phoneCtrl = TextEditingController(text: c.phone);
    _cnicCtrl = TextEditingController(text: c.cnic);
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
    _ibnCtrl = TextEditingController(text: c.ibnNo);
    _accountTypeDisplayCtrl = TextEditingController(text: c.accountType);
    _accountNumberDisplayCtrl = TextEditingController(text: c.accountNumber);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _ibnCtrl.dispose();
    _accountTypeDisplayCtrl.dispose();
    _accountNumberDisplayCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.currentUser.can('edit');
  bool get _canDelete => widget.currentUser.can('delete');

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = Customer(
        accountNumber: widget.customer.accountNumber,
        name: _nameCtrl.text.trim(),
        accountTitle: _accountTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: widget.customer.accountType,
        ibnNo: _ibnCtrl.text.trim(),
        status: widget.customer.status,
        dateOpened: widget.customer.dateOpened,
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
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
      appBar: AppBar(title: const Text('Customer Details')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            SectionCard(
              title: 'Customer Details',
              children: [
                AccountField(label: 'Full Name', controller: _nameCtrl, readOnly: !_canEdit, validator: Validators.requiredName),
                const SizedBox(height: 16),
                AccountField(label: 'Account Title', controller: _accountTitleCtrl, readOnly: !_canEdit, validator: Validators.accountTitle),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Account Number',
                  controller: _accountNumberDisplayCtrl,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'IBN No.',
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
                AccountField(label: 'Account Type', controller: _accountTypeDisplayCtrl, readOnly: true),
                const SizedBox(height: 16),
                AccountField(
                  label: 'CNIC No.',
                  controller: _cnicCtrl,
                  readOnly: !_canEdit,
                  validator: Validators.cnic,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                ),
                const SizedBox(height: 16),
                AccountField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  readOnly: !_canEdit,
                  validator: Validators.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                ),
                const SizedBox(height: 16),
                AccountField(label: 'Address', controller: _addressCtrl, readOnly: !_canEdit),
                const SizedBox(height: 16),
                AccountField(label: 'Notes', controller: _notesCtrl, readOnly: !_canEdit),
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
}
