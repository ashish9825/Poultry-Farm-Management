import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/customer_model.dart';

class QuickUpdateScreen extends StatefulWidget {
  const QuickUpdateScreen({super.key});

  @override
  State<QuickUpdateScreen> createState() => _QuickUpdateScreenState();
}

class _QuickUpdateScreenState extends State<QuickUpdateScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;

  static const _accentColor = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final list = await DatabaseService.instance.getCustomers();
    setState(() {
      _allCustomers = list;
      _filtered = list;
      _isLoading = false;
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allCustomers
          : _allCustomers
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.symbolNumber.toLowerCase().contains(q))
              .toList();
    });
  }

  void _openAddSheet(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBatchSheet(
        customer: customer,
        accentColor: _accentColor,
        onUpdated: _loadCustomers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _accentColor,
        elevation: 0,
        title: const Text(
          'Quick Update',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_allCustomers.length} customers',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Find a returning customer to add chickens, weight,\ndeposit — or just record a debt payment.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or symbol / ID…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: Colors.white70),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white70),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.18),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Results list ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _accentColor))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded,
                                size: 72,
                                color: _accentColor.withOpacity(0.35)),
                            const SizedBox(height: 14),
                            Text(
                              _searchCtrl.text.isEmpty
                                  ? 'No customers found.\nAdd customers from Manage Customers.'
                                  : 'No match for "${_searchCtrl.text}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        color: _accentColor,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _customerTile(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _customerTile(Customer c) {
    final fmt = NumberFormat('#,##0.00');
    final hasPending = c.remainingAmount > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAddSheet(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withOpacity(0.12),
                  image: c.imagePath != null && File(c.imagePath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(c.imagePath!)),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: c.imagePath == null
                    ? Icon(Icons.person_rounded, color: _accentColor, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),

                    // Symbol · chicks · weight row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag, size: 11, color: _accentColor),
                            const SizedBox(width: 3),
                            Text(c.symbolNumber,
                                style: TextStyle(
                                    color: _accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.egg_alt_rounded,
                                size: 11, color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text('${c.numberOfChicks} chicks',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale_outlined,
                                size: 11, color: AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text('${c.chickenWeight} kg',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Paid + Remaining row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Paid chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 11, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Paid: Rs. ${fmt.format(c.depositAmount)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),

                        // Remaining chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasPending
                                ? AppTheme.error.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasPending
                                    ? Icons.pending_rounded
                                    : Icons.done_all_rounded,
                                size: 11,
                                color: hasPending
                                    ? AppTheme.error
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasPending
                                    ? 'Due: Rs. ${fmt.format(c.remainingAmount)}'
                                    : 'Cleared ✓',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasPending
                                        ? AppTheme.error
                                        : Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tap hint
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.add_circle_rounded, color: _accentColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom sheet — ADD a new batch / record a payment for the selected customer
// ══════════════════════════════════════════════════════════════════════════════
class _AddBatchSheet extends StatefulWidget {
  final Customer customer;
  final Color accentColor;
  final VoidCallback onUpdated;

  const _AddBatchSheet({
    required this.customer,
    required this.accentColor,
    required this.onUpdated,
  });

  @override
  State<_AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends State<_AddBatchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _chicksCtrl  = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _paymentMethod = 'Cash';
  bool _saving = false;

  static const _paymentMethods = ['Cash', 'Bank Transfer', 'eSewa', 'Khalti', 'Cheque', 'Other'];

  // Computed updated totals
  int    _newTotalChicks  = 0;
  double _newTotalWeight  = 0;
  double _newTotalDeposit = 0;
  double _newTotalAmount  = 0;
  double _newRemaining    = 0;

  @override
  void initState() {
    super.initState();
    _recalculate();
    _chicksCtrl.addListener(_recalculate);
    _weightCtrl.addListener(_recalculate);
    _depositCtrl.addListener(_recalculate);
  }

  @override
  void dispose() {
    _chicksCtrl.dispose();
    _weightCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final c          = widget.customer;
    final addChicks  = int.tryParse(_chicksCtrl.text.trim()) ?? 0;
    final addWeight  = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final addDeposit = double.tryParse(_depositCtrl.text.trim()) ?? 0;

    setState(() {
      _newTotalChicks  = c.numberOfChicks + addChicks;
      _newTotalWeight  = c.chickenWeight  + addWeight;
      _newTotalDeposit = c.depositAmount  + addDeposit;
      // Total amount is based on combined weight × rate
      _newTotalAmount  = _newTotalWeight  * c.chickenRate;
      _newRemaining    = _newTotalAmount  - _newTotalDeposit;
    });
  }

  /// At least one field must have a value before saving.
  bool get _hasAnyInput =>
      _chicksCtrl.text.trim().isNotEmpty ||
      _weightCtrl.text.trim().isNotEmpty ||
      _depositCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one value to update.')),
      );
      return;
    }
    setState(() => _saving = true);

    final updated = widget.customer.copyWith(
      numberOfChicks: _newTotalChicks,
      chickenWeight:  _newTotalWeight,
      depositAmount:  _newTotalDeposit,
      paymentMode:    _paymentMethod,
    );
    await DatabaseService.instance.updateCustomer(updated);

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final c      = widget.customer;
    final fmt    = NumberFormat('#,##0.00');
    final accent = widget.accentColor;
    final hasPending = c.remainingAmount > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Customer header ──────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.12),
                      image: c.imagePath != null &&
                              File(c.imagePath!).existsSync()
                          ? DecorationImage(
                              image: FileImage(File(c.imagePath!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: c.imagePath == null
                        ? Icon(Icons.person_rounded, color: accent, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                          '# ${c.symbolNumber}  ·  Rate: Rs. ${fmt.format(c.chickenRate)}/kg',
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Current totals banner (4 chips) ─────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statChip(Icons.egg_alt_rounded, '${c.numberOfChicks}',
                        'chicks', accent),
                    _divider(),
                    _statChip(Icons.scale_outlined, '${c.chickenWeight} kg',
                        'weight', accent),
                    _divider(),
                    _statChip(
                      Icons.payments_rounded,
                      'Rs. ${fmt.format(c.depositAmount)}',
                      'paid',
                      Colors.green.shade700,
                    ),
                    _divider(),
                    _statChip(
                      hasPending
                          ? Icons.pending_rounded
                          : Icons.done_all_rounded,
                      hasPending
                          ? 'Rs. ${fmt.format(c.remainingAmount)}'
                          : 'Clear',
                      'remaining',
                      hasPending ? AppTheme.error : Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 12),

              // ── Section label ────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Add This Visit\'s Data',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'All fields are optional. Fill only what applies — e.g. just the deposit to clear a debt.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // ── Chickens ─────────────────────────────────────────────
              _field(
                controller: _chicksCtrl,
                label: 'Number of Chickens (to add)',
                icon: Icons.egg_alt_rounded,
                keyboard: TextInputType.number,
                accent: accent,
              ),
              const SizedBox(height: 12),

              // ── Weight ───────────────────────────────────────────────
              _field(
                controller: _weightCtrl,
                label: 'Weight to Add (kg)',
                icon: Icons.scale_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                accent: accent,
              ),
              const SizedBox(height: 12),

              // ── Deposit (fully independent) ───────────────────────────
              _field(
                controller: _depositCtrl,
                label: 'Payment / Deposit (Rs.)',
                icon: Icons.payments_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                accent: accent,
                hint: 'Enter 0 or leave blank if no payment this visit',
              ),
              const SizedBox(height: 12),

              // ── Payment Method dropdown ───────────────────────────────
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon:
                      Icon(Icons.credit_card_rounded, color: accent, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
              ),
              const SizedBox(height: 16),

              // ── Updated totals preview (shows when any field has input) ─
              if (_hasAnyInput)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updated Totals After Save',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent),
                      ),
                      const SizedBox(height: 10),
                      _calcRow(Icons.egg_alt_rounded, 'Total Chickens',
                          '$_newTotalChicks chicks', accent),
                      const SizedBox(height: 6),
                      _calcRow(Icons.scale_rounded, 'Total Weight',
                          '${fmt.format(_newTotalWeight)} kg', accent),
                      const SizedBox(height: 6),
                      _calcRow(Icons.receipt_long_rounded, 'Total Amount',
                          'Rs. ${fmt.format(_newTotalAmount)}', accent),
                      const SizedBox(height: 6),
                      _calcRow(Icons.payments_rounded, 'Total Paid',
                          'Rs. ${fmt.format(_newTotalDeposit)}',
                          Colors.green.shade700),
                      const Divider(height: 14),
                      _calcRow(
                        Icons.account_balance_rounded,
                        'Remaining Due',
                        'Rs. ${fmt.format(_newRemaining < 0 ? 0 : _newRemaining)}',
                        _newRemaining > 0 ? AppTheme.error : Colors.green,
                        bold: true,
                      ),
                      if (_newRemaining < 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Overpaid by Rs. ${fmt.format(_newRemaining.abs())}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              // ── Save button ──────────────────────────────────────────
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _saving ? 'Saving…' : 'ADD & UPDATE',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.grey.shade300,
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accent,
    TextInputType? keyboard,
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: accent, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _calcRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color)),
      ],
    );
  }
}
