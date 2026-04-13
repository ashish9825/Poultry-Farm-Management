import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/labour_model.dart';

class LabourScreen extends StatefulWidget {
  const LabourScreen({super.key});
  @override
  State<LabourScreen> createState() => _LabourScreenState();
}

class _LabourScreenState extends State<LabourScreen> {
  List<Labour> _labours = [];
  List<Labour> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();
  static const Color _purple = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _loadLabours();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _labours : _labours.where((l) =>
        l.name.toLowerCase().contains(q) || l.role.toLowerCase().contains(q) || l.mobileNo.contains(q)
      ).toList();
    });
  }

  Future<void> _loadLabours() async {
    setState(() => _isLoading = true);
    final labours = await DatabaseService.instance.getLabours();
    setState(() {
      _labours = labours;
      _filtered = labours;
      _isLoading = false;
    });
  }

  double get _totalWages => _labours.fold(0, (sum, l) => sum + l.totalEarned);
  double get _totalPaid => _labours.fold(0, (sum, l) => sum + l.totalPaid);
  double get _totalPending => _labours.fold(0, (sum, l) => sum + l.remainingPayment);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Labour'),
        backgroundColor: _purple,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${_labours.length} staff', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            color: _purple,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search labour...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    fillColor: Colors.white.withOpacity(0.2),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                if (_labours.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _summaryPill('Total Wages', 'Rs. ${fmt.format(_totalWages)}'),
                      const SizedBox(width: 8),
                      _summaryPill('Paid', 'Rs. ${fmt.format(_totalPaid)}'),
                      const SizedBox(width: 8),
                      _summaryPill('Pending', 'Rs. ${fmt.format(_totalPending)}', isAlert: _totalPending > 0),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _purple))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.engineering_rounded, size: 70, color: _purple),
                        const SizedBox(height: 12),
                        Text(_searchCtrl.text.isEmpty ? 'No labour records yet' : 'No results found', style: const TextStyle(color: AppTheme.textSecondary)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadLabours,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _labourCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLabourForm(),
        backgroundColor: _purple,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Labour'),
      ),
    );
  }

  Widget _summaryPill(String label, String value, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isAlert ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _labourCard(Labour labour) {
    final fmt = NumberFormat('#,##0.00');
    final hasPending = labour.remainingPayment > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: _purple.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.engineering_rounded, color: _purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labour.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _purple.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(labour.role, style: const TextStyle(color: _purple, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(labour.mobileNo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasPending ? AppTheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(hasPending ? 'Pending' : 'Paid', style: TextStyle(color: hasPending ? AppTheme.error : Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                _miniStat('Days', '${labour.totalDaysWorked}', Icons.calendar_today_outlined),
                _miniStat('Daily Wage', 'Rs. ${fmt.format(labour.dailyWage)}', Icons.paid_outlined),
                _miniStat('Total Earned', 'Rs. ${fmt.format(labour.totalEarned)}', Icons.account_balance_wallet_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _paymentBar('Paid', labour.totalPaid, labour.totalEarned, Colors.green),
                ),
                const SizedBox(width: 8),
                if (hasPending) Expanded(
                  child: _paymentBar('Pending', labour.remainingPayment, labour.totalEarned, AppTheme.error),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Joined: ${labour.joiningDate}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openLabourForm(existing: labour),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: _purple),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteLabour(labour),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: _purple),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _paymentBar(String label, double amount, double total, Color color) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text('Rs. ${fmt.format(amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Future<void> _deleteLabour(Labour labour) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Labour'),
        content: Text('Delete "${labour.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.deleteLabour(labour.id);
      _loadLabours();
    }
  }

  Future<void> _openLabourForm({Labour? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final mobileCtrl = TextEditingController(text: existing?.mobileNo ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final dateCtrl = TextEditingController(text: existing?.joiningDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final wageCtrl = TextEditingController(text: existing?.dailyWage.toString() ?? '');
    final daysCtrl = TextEditingController(text: existing?.totalDaysWorked.toString() ?? '');
    final paidCtrl = TextEditingController(text: existing?.totalPaid.toString() ?? '');
    String role = existing?.role ?? 'General Worker';

    final calc = ValueNotifier<String>('');
    void recalc() {
      final wage = double.tryParse(wageCtrl.text) ?? 0;
      final days = int.tryParse(daysCtrl.text) ?? 0;
      final paid = double.tryParse(paidCtrl.text) ?? 0;
      final total = wage * days;
      final remaining = total - paid;
      calc.value = 'Total Earned: Rs. ${NumberFormat('#,##0.00').format(total)}  |  Remaining: Rs. ${NumberFormat('#,##0.00').format(remaining)}';
    }
    wageCtrl.addListener(recalc);
    daysCtrl.addListener(recalc);
    paidCtrl.addListener(recalc);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(existing == null ? 'Add Labour' : 'Edit Labour', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _field(nameCtrl, 'Full Name', Icons.person_outline, required: true),
                  const SizedBox(height: 12),
                  _field(mobileCtrl, 'Mobile Number', Icons.phone_outlined, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(addressCtrl, 'Address', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _dateField(dateCtrl, ctx),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role/Position', prefixIcon: Icon(Icons.work_outline, color: _purple)),
                    items: ['General Worker', 'Supervisor', 'Feeder', 'Cleaner', 'Driver', 'Veterinary Assistant']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setModalState(() => role = v!),
                  ),
                  const SizedBox(height: 12),
                  _field(wageCtrl, 'Daily Wage (Rs.)', Icons.paid_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true), required: true),
                  const SizedBox(height: 12),
                  _field(daysCtrl, 'Total Days Worked', Icons.calendar_today_outlined, keyboard: TextInputType.number, required: true),
                  const SizedBox(height: 12),
                  _field(paidCtrl, 'Amount Paid (Rs.)', Icons.account_balance_wallet_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: calc,
                    builder: (_, val, __) => val.isEmpty ? const SizedBox.shrink() : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(val, style: const TextStyle(color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _purple),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final labour = Labour(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        mobileNo: mobileCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        joiningDate: dateCtrl.text,
                        dailyWage: double.tryParse(wageCtrl.text) ?? 0,
                        totalDaysWorked: int.tryParse(daysCtrl.text) ?? 0,
                        totalPaid: double.tryParse(paidCtrl.text) ?? 0,
                        role: role,
                        createdAt: existing?.createdAt,
                      );
                      if (existing == null) {
                        await DatabaseService.instance.insertLabour(labour);
                      } else {
                        await DatabaseService.instance.updateLabour(labour);
                      }
                      Navigator.pop(ctx);
                      _loadLabours();
                    },
                    child: Text(existing == null ? 'ADD LABOUR' : 'UPDATE LABOUR'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: _purple)),
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _dateField(TextEditingController ctrl, BuildContext ctx) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: const InputDecoration(labelText: 'Joining Date', prefixIcon: Icon(Icons.calendar_today_outlined, color: _purple)),
      onTap: () async {
        final picked = await showDatePicker(context: ctx, initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      },
    );
  }
}
