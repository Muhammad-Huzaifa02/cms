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
  static const _accountTypes = ['Current', 'Savings', 'Current Plus', 'Business'];

  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  final _nameCtrl = TextEditingController();
  final _accountTitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _accountType = _accountTypes.first;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountTitleCtrl.dispose();
    _phoneCtrl.dispose();
    _cnicCtrl.dispose();
    _accountCtrl.dispose();
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
                const Text('Account Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 6),
                // DropdownButton inside an InputDecorator (rather than
                // DropdownButtonFormField) so it picks up the app's themed
                // input look without relying on `value`, which newer
                // Flutter SDKs have deprecated on the FormField variant.
                InputDecorator(
                  decoration: const InputDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _accountType,
                      isExpanded: true,
                      isDense: true,
                      items: _accountTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _accountType = v);
                      },
                    ),
                  ),
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
}
