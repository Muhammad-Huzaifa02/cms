import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/customer_service.dart';
import '../../../core/theme/app_theme.dart';

class AddCustomerScreen extends StatefulWidget {
  final AppUser currentUser;
  const AddCustomerScreen({super.key, required this.currentUser});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _service = CustomerService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _accountType = 'Current';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _accountCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name and account number are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final customer = Customer(
        accountNumber: _accountCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: _accountType,
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
      appBar: AppBar(title: const Text('Add customer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input('Full name', _nameCtrl),
          _input('Phone number', _phoneCtrl, keyboard: TextInputType.phone),
          _input('CNIC number', _cnicCtrl, hint: 'xxxxx-xxxxxxx-x'),
          _input('Account number', _accountCtrl),
          const Padding(
            padding: EdgeInsets.only(bottom: 6, top: 2),
            child: Text('ACCOUNT TYPE', style: TextStyle(fontSize: 9.5, color: AppColors.muted, letterSpacing: 0.5)),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _accountType,
                  isExpanded: true,
                  items: const ['Current', 'Savings', 'Current Plus', 'Business']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _accountType = v);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _input('Address (optional)', _addressCtrl),
          _input('Notes (optional)', _notesCtrl),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save customer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
