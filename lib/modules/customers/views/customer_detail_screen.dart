import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

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
  }

  bool get _canEdit => widget.currentUser.can('edit');
  bool get _canDelete => widget.currentUser.can('delete');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

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
      appBar: AppBar(title: const Text('Customer details')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Full name', _nameCtrl, editable: _canEdit, validator: Validators.requiredName),
            _field('Account Title', _accountTitleCtrl, editable: _canEdit, validator: Validators.accountTitle),
            _field(
              'Phone',
              _phoneCtrl,
              editable: _canEdit,
              validator: Validators.phone,
              keyboard: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            ),
            _field(
              'CNIC',
              _cnicCtrl,
              editable: _canEdit,
              validator: Validators.cnic,
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
            ),
            // Account number is intentionally NOT editable here: it's the
            // Firestore document ID (see Customer model docs), so
            // "changing" it isn't a field update — it would mean deleting
            // this document and creating a new one under a different ID,
            // which would silently orphan every activityLog entry that
            // references this account number by ID. If a customer's
            // account number genuinely needs to change, that should be a
            // deliberate Admin action (delete + re-add), not something
            // that happens implicitly from an edit form.
            _maskedField('Account number', c.maskedAccountNumber, c.accountNumber, _acctRevealed, () => setState(() => _acctRevealed = !_acctRevealed)),
            _readOnlyField('Account type', c.accountType),
            _field('Address', _addressCtrl, editable: _canEdit),
            _field('Notes', _notesCtrl, editable: _canEdit),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            const SizedBox(height: 8),
            if (_canEdit)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes'),
                ),
              ),
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required bool editable,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.5)),
              TextFormField(
                controller: ctrl,
                enabled: editable,
                validator: editable ? validator : null,
                keyboardType: keyboard,
                inputFormatters: formatters,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, filled: false, isDense: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _maskedField(String label, String masked, String full, bool revealed, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.5)),
                    const SizedBox(height: 3),
                    Text(revealed ? full : masked, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onToggle,
                child: Text(revealed ? 'Hide' : 'Reveal', style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
