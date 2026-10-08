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
  late TextEditingController _nameCtrl, _accountTitleCtrl, _phoneCtrl, _cnicCtrl, _addressCtrl, _notesCtrl;
  // Display-only controllers for fields that are never actually edited
  // (Account Number toggles masked/full text, Account Type is fixed) —
  // kept as persistent fields rather than constructed inline in build(),
  // since a TextEditingController passed in explicitly is NOT
  // auto-disposed by TextField, so creating one fresh on every rebuild
  // (e.g. every time the reveal toggle is tapped) would leak one each time.
  late final TextEditingController _accountNumberDisplayCtrl;
  late final TextEditingController _accountTypeDisplayCtrl;
  late final TextEditingController _cnicMaskedDisplayCtrl;

  // CNIC and Account Number stay masked by default for EVERYONE — edit
  // permission does not imply "should see it unmasked at a glance". Each
  // has its own reveal toggle, independent of whether editing is allowed.
  bool _cnicRevealed = false;
  bool _acctRevealed = false;
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
    _accountNumberDisplayCtrl = TextEditingController(text: c.maskedAccountNumber);
    _accountTypeDisplayCtrl = TextEditingController(text: c.accountType);
    _cnicMaskedDisplayCtrl = TextEditingController(text: c.maskedCnic);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _accountNumberDisplayCtrl.dispose();
    _accountTypeDisplayCtrl.dispose();
    _cnicMaskedDisplayCtrl.dispose();
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
    final c = widget.customer;
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
              title: 'Customer Information',
              children: [
                AccountField(label: 'Full Name', controller: _nameCtrl, readOnly: !_canEdit, validator: Validators.requiredName),
                const SizedBox(height: 16),
                AccountField(label: 'Account Title', controller: _accountTitleCtrl, readOnly: !_canEdit, validator: Validators.accountTitle),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Contact Information',
              children: [
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
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Account Information',
              children: [
                _revealableCnic(),
                const SizedBox(height: 16),
                // Account Number is intentionally NEVER editable here —
                // it's the Firestore document ID (see Customer model
                // docs), so "changing" it isn't a field update, it would
                // mean deleting this document and creating a new one
                // under a different ID, which would silently orphan
                // every activityLog entry that references this account
                // number by ID. If a customer's account number
                // genuinely needs to change, that should be a
                // deliberate Admin action (delete + re-add), not
                // something that happens implicitly from an edit form.
                AccountField(
                  label: 'Account Number',
                  controller: _accountNumberDisplayCtrl..text = _acctRevealed ? c.accountNumber : c.maskedAccountNumber,
                  readOnly: true,
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _acctRevealed = !_acctRevealed),
                    child: Text(_acctRevealed ? 'Hide' : 'Reveal', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                AccountField(label: 'Account Type', controller: _accountTypeDisplayCtrl, readOnly: true),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Notes',
              children: [
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

  /// CNIC stays masked by default for every viewer, edit permission or
  /// not. Revealing it shows the real value — editable if the viewer has
  /// edit permission, read-only otherwise. This is deliberately NOT just
  /// "AccountField with readOnly: !_canEdit" the way the other fields
  /// are, because masking has to apply independently of editability.
  Widget _revealableCnic() {
    if (!_cnicRevealed) {
      return AccountField(
        label: 'CNIC',
        controller: _cnicMaskedDisplayCtrl,
        readOnly: true,
        suffixIcon: TextButton(
          onPressed: () => setState(() => _cnicRevealed = true),
          child: const Text('Reveal', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return AccountField(
      label: 'CNIC',
      controller: _cnicCtrl,
      readOnly: !_canEdit,
      validator: Validators.cnic,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
      suffixIcon: TextButton(
        onPressed: () => setState(() => _cnicRevealed = false),
        child: const Text('Hide', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
