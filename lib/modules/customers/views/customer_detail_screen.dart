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
///
/// Designed with priority on readability, high contrast, and rapid data access:
/// - In View Mode: Displays a prominent customer profile header, quick-action
///   copy buttons, and crystal-clear high-contrast detail tiles with 1-tap clipboard copy.
/// - In Edit Mode: Fully unlocked inputs for all fields including Account Number
///   and Account Type, arranged in the exact standardized 9-field sequence.
///
/// Exact 9-Field Standard Sequence:
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

  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();
  static const _statusOptions = ['Active', 'Inactive', 'Dormant', 'Blocked'];

  late TextEditingController _accountTitleCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _ibnCtrl;
  late TextEditingController _cnicCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late String _status;
  late String _accountCategory;
  late String _accountType;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _accountTitleCtrl = TextEditingController(text: c.accountTitle);
    _accountNumberCtrl = TextEditingController(text: c.accountNumber);
    _ibnCtrl = TextEditingController(text: c.ibnNo);
    _cnicCtrl = TextEditingController(text: c.cnic);
    _phoneCtrl = TextEditingController(text: c.phone);
    _emailCtrl = TextEditingController(text: c.email ?? '');
    _addressCtrl = TextEditingController(text: c.address ?? '');
    _status = _statusOptions.contains(c.status) ? c.status : _statusOptions.first;

    // Resolve initial category from customer's account type
    _accountType = c.accountType;
    String matchedCategory = _accountCategories.first;
    for (final entry in _accountTypesByCategory.entries) {
      if (entry.value.contains(c.accountType)) {
        matchedCategory = entry.key;
        break;
      }
    }
    _accountCategory = matchedCategory;
  }

  @override
  void dispose() {
    _accountTitleCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ibnCtrl.dispose();
    _cnicCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.currentUser.can('edit');
  bool get _canDelete => widget.currentUser.can('delete');

  void _copyToClipboard(String label, String value) {
    if (value.trim().isEmpty || value == 'Not provided') return;
    Clipboard.setData(ClipboardData(text: value.trim()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  LinearGradient _getAvatarGradient(String accountType) {
    final lower = accountType.toLowerCase();
    if (lower.contains('saving')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.brandDeep, AppColors.brand],
      );
    } else if (lower.contains('current')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      );
    } else if (lower.contains('business') || lower.contains('corporate')) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF78350F), Color(0xFFD97706)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.brandDeep, AppColors.brandLight],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'dormant':
        return const Color(0xFFD97706);
      case 'blocked':
        return AppColors.danger;
      case 'inactive':
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final newAccountNum = _accountNumberCtrl.text.trim();
      final updated = Customer(
        accountNumber: newAccountNum,
        name: _accountTitleCtrl.text.trim(),
        accountTitle: _accountTitleCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        accountType: _accountType,
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
      await _service.updateCustomer(
        updated,
        widget.currentUser,
        originalAccountNumber: widget.customer.accountNumber,
        originalPhone: widget.customer.phone,
        originalCnic: widget.customer.cnic,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer updated successfully.')));
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
        content: const Text('This customer record will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
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
          if (!widget.isEditable && widget.allowEditAction && _canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonalIcon(
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
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandSoft,
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: widget.isEditable ? _buildEditForm() : _buildViewMode(),
    );
  }

  /// High-contrast, crystal-clear View Mode.
  Widget _buildViewMode() {
    final c = widget.customer;
    final titleText = c.accountTitle.trim().isNotEmpty ? c.accountTitle.trim() : c.name.trim();
    final initials = titleText.isEmpty
        ? '?'
        : titleText.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final statusColor = _getStatusColor(c.status);
    final statusText = c.status.trim().isNotEmpty ? c.status.trim() : 'Active';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── HERO PROFILE HEADER CARD ──
        Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getAvatarGradient(c.accountType),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Status pill with colored dot
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusText.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Account Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.brandSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.accountType,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 9 STANDARDIZED FIELDS (EXACT SEQUENCE) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Text(
                'CUSTOMER DATA RECORD',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1.1,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Tap any field to copy',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.brand.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 1. Account Title
        _DetailFieldTile(
          icon: Icons.person_pin_rounded,
          label: 'Account Title',
          value: c.accountTitle.isNotEmpty ? c.accountTitle : c.name,
          onCopy: () => _copyToClipboard('Account Title', c.accountTitle.isNotEmpty ? c.accountTitle : c.name),
        ),

        // 2. Account Number
        _DetailFieldTile(
          icon: Icons.credit_card_rounded,
          label: 'Account Number',
          value: c.accountNumber,
          isMonospace: true,
          onCopy: () => _copyToClipboard('Account Number', c.accountNumber),
        ),

        // 3. IBAN No
        _DetailFieldTile(
          icon: Icons.account_balance_rounded,
          label: 'IBAN No.',
          value: c.ibnNo.isNotEmpty ? c.ibnNo : 'Not provided',
          isMonospace: c.ibnNo.isNotEmpty,
          onCopy: c.ibnNo.isNotEmpty ? () => _copyToClipboard('IBAN', c.ibnNo) : null,
        ),

        // 4. Account Type
        _DetailFieldTile(
          icon: Icons.category_rounded,
          label: 'Account Type',
          value: c.accountType,
          onCopy: () => _copyToClipboard('Account Type', c.accountType),
        ),

        // 5. Account Status
        _DetailFieldTile(
          icon: Icons.verified_rounded,
          label: 'Account Status',
          value: statusText,
          statusColor: statusColor,
          onCopy: () => _copyToClipboard('Account Status', statusText),
        ),

        // 6. CNIC
        _DetailFieldTile(
          icon: Icons.badge_rounded,
          label: 'CNIC',
          value: c.cnic,
          isMonospace: true,
          onCopy: () => _copyToClipboard('CNIC', c.cnic),
        ),

        // 7. Phone Number
        _DetailFieldTile(
          icon: Icons.phone_rounded,
          label: 'Phone Number',
          value: c.phone,
          isMonospace: true,
          onCopy: () => _copyToClipboard('Phone Number', c.phone),
        ),

        // 8. Email
        _DetailFieldTile(
          icon: Icons.email_rounded,
          label: 'Email',
          value: c.email != null && c.email!.trim().isNotEmpty ? c.email!.trim() : 'Not provided',
          isMutedIfEmpty: c.email == null || c.email!.trim().isEmpty,
          onCopy: c.email != null && c.email!.trim().isNotEmpty
              ? () => _copyToClipboard('Email', c.email!.trim())
              : null,
        ),

        // 9. Address
        _DetailFieldTile(
          icon: Icons.location_on_rounded,
          label: 'Address',
          value: c.address != null && c.address!.trim().isNotEmpty ? c.address!.trim() : 'Not provided',
          isMutedIfEmpty: c.address == null || c.address!.trim().isEmpty,
          onCopy: c.address != null && c.address!.trim().isNotEmpty
              ? () => _copyToClipboard('Address', c.address!.trim())
              : null,
        ),

        const SizedBox(height: 12),
        if (widget.allowEditAction && _canEdit)
          PrimaryButton(
            label: 'Edit Customer Details',
            loading: false,
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
    );
  }

  /// High-contrast Edit Form with unlocked Account Number and Account Type.
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
              // 2. Account Number (UNLOCKED)
              AccountField(
                label: 'Account Number',
                controller: _accountNumberCtrl,
                readOnly: !_canEdit,
                validator: Validators.accountNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
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
              // 4. Account Type (UNLOCKED: Category + Type Dropdowns)
              const Text('Account Category', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              _dropdown(
                value: _accountCategory,
                options: _accountCategories,
                enabled: _canEdit,
                onChanged: (category) {
                  if (category == null) return;
                  setState(() {
                    _accountCategory = category;
                    _accountType = _accountTypesByCategory[category]!.first;
                  });
                },
              ),
              const SizedBox(height: 14),
              const Text('Account Type', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 6),
              _dropdown(
                value: _accountType,
                options: _accountTypesByCategory[_accountCategory] ?? [_accountType],
                enabled: _canEdit,
                onChanged: (type) {
                  if (type != null) setState(() => _accountType = type);
                },
              ),
              const SizedBox(height: 16),
              // 5. Account Status
              const Text('Account Status', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
          const SizedBox(height: 20),
          if (_canEdit) PrimaryButton(label: 'Save Changes', loading: _saving, onPressed: _save),
          if (_canDelete)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  label: const Text('Delete this record', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> options,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    // Ensure value is present in options list to avoid dropdown assertion error
    final safeValue = options.contains(value) ? value : options.first;
    return InputDecorator(
      decoration: const InputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          menuMaxHeight: 360,
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

/// Crystal-clear, high-contrast, tap-to-copy customer data tile.
class _DetailFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;
  final bool isMutedIfEmpty;
  final Color? statusColor;
  final VoidCallback? onCopy;

  const _DetailFieldTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.isMutedIfEmpty = false,
    this.statusColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4ECE8), width: 1.2),
      ),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (statusColor ?? AppColors.brand).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: statusColor ?? AppColors.brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (statusColor != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            value.toUpperCase(),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: isMonospace ? 16 : 15.5,
                          fontWeight: FontWeight.w700,
                          color: isMutedIfEmpty ? AppColors.muted : AppColors.ink,
                          fontStyle: isMutedIfEmpty ? FontStyle.italic : FontStyle.normal,
                          letterSpacing: isMonospace ? 0.9 : 0.1,
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 19, color: AppColors.brand),
                  tooltip: 'Copy $label',
                  onPressed: onCopy,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
