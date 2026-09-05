import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/theme/app_theme.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  final AppUser currentUser;
  const CustomerDetailScreen({super.key, required this.customer, required this.currentUser});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _service = CustomerService();
  late TextEditingController _nameCtrl, _phoneCtrl, _addressCtrl, _notesCtrl;
  bool _cnicRevealed = false;
  bool _acctRevealed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c.name);
    _phoneCtrl = TextEditingController(text: c.phone);
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _notesCtrl = TextEditingController(text: c.notes ?? '');
  }

  bool get _canEdit => widget.currentUser.can('edit');
  bool get _canDelete => widget.currentUser.can('delete');

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = Customer(
        accountNumber: widget.customer.accountNumber,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: widget.customer.cnic,
        accountType: widget.customer.accountType,
        dateOpened: widget.customer.dateOpened,
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        createdBy: widget.customer.createdBy,
        createdAt: widget.customer.createdAt,
        updatedBy: widget.currentUser.uid,
      );
      await _service.updateCustomer(updated, widget.currentUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Full name', _nameCtrl, editable: _canEdit),
          _field('Phone', _phoneCtrl, editable: _canEdit),
          _maskedField('CNIC', c.maskedCnic, c.cnic, _cnicRevealed, () => setState(() => _cnicRevealed = !_cnicRevealed)),
          _maskedField('Account number', c.maskedAccountNumber, c.accountNumber, _acctRevealed, () => setState(() => _acctRevealed = !_acctRevealed)),
          _readOnlyField('Account type', c.accountType),
          _field('Address', _addressCtrl, editable: _canEdit),
          _field('Notes', _notesCtrl, editable: _canEdit),
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
    );
  }

  Widget _field(String label, TextEditingController ctrl, {required bool editable}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.5)),
              TextField(
                controller: ctrl,
                enabled: editable,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero, filled: false),
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
