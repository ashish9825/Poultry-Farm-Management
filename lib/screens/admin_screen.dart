import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/farm_data_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _summary = {
    'income': 0,
    'expense': 0,
    'profit': 0,
    'labourCost': 0
  };
  List<FarmData> _farmDataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final summary = await DatabaseService.instance.getSummary();
    final farmData = await DatabaseService.instance.getFarmData();
    setState(() {
      _summary = summary;
      _farmDataList = farmData;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Farm Data',
            onPressed: _showAddFarmDataDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Financial Summary'),
            Tab(icon: Icon(Icons.agriculture_rounded), text: 'Farm Data'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildSummaryTab(), _buildFarmDataTab()],
            ),
      floatingActionButton: Builder(
        builder: (context) {
          // Show button only on Farm Data tab
          if (_tabController.index == 1 && !_isLoading) {
            return FloatingActionButton.extended(
              onPressed: _showAddFarmDataDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Farm Data'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryTab() {
    final profit = _summary['profit'] ?? 0;
    final isProfit = profit >= 0;
    final fmt = NumberFormat('#,##0.00');
    final chicksInFarm = _summary['chicksInFarm']?.toInt() ?? 0;
    final averageSoldWeight = _summary['averageSoldWeight'] ?? 0;
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main profit card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfit
                      ? [AppTheme.primary, AppTheme.primaryLight]
                      : [AppTheme.error, const Color(0xFFEF5350)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: (isProfit ? AppTheme.primary : AppTheme.error)
                          .withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                children: [
                  Text(isProfit ? 'NET PROFIT' : 'NET LOSS',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Rs. ${fmt.format(profit.abs())}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900)),
                  Icon(isProfit ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white70, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Flock Status',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            _statCard('Current Flock (Est.)', chicksInFarm.toDouble(), Icons.pets, Colors.orange, fullWidth: true, isCount: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statCard('Total Added', _summary['totalChicksAdded'] ?? 0, Icons.add_circle_outline, AppTheme.primary, isCount: true)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Total Sold', _summary['totalSoldChicks'] ?? 0, Icons.outbox, Colors.green, isCount: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statCard('Dead Chicks', _summary['totalDeadChicks'] ?? 0, Icons.warning_amber_rounded, AppTheme.error, isCount: true)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Avg Sold Wt', averageSoldWeight, Icons.scale, Colors.blue, isWeight: true)),
              ],
            ),
            
            const SizedBox(height: 24),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Financial Overview',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _statCard('Total Income', _summary['income'] ?? 0,
                        Icons.arrow_circle_down_rounded, Colors.green)),
                const SizedBox(width: 12),
                Expanded(
                    child: _statCard('Total Expense', _summary['expense'] ?? 0,
                        Icons.arrow_circle_up_rounded, AppTheme.error)),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Expense Breakdown',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            _breakdownRow('Chicks Purchase', _summary['chicksAmount'] ?? 0, AppTheme.primary),
            _breakdownRow('Feed & Grains', _summary['feedCost'] ?? 0, const Color(0xFFE65100)),
            _breakdownRow('Medicine', _summary['medicineCost'] ?? 0, const Color(0xFF0288D1)),
            _breakdownRow('Labour Cost', _summary['labourCost'] ?? 0, const Color(0xFF6A1B9A)),
            _breakdownRow('Other Expenses', (_summary['expense'] ?? 0) - (_summary['chicksAmount'] ?? 0) - (_summary['feedCost'] ?? 0) - (_summary['medicineCost'] ?? 0) - (_summary['labourCost'] ?? 0), AppTheme.error),
            const Divider(height: 24),
            _breakdownRow('Net ${isProfit ? "Profit" : "Loss"}', profit,
                isProfit ? Colors.green : AppTheme.error,
                bold: true),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, double value, IconData icon, Color color,
      {bool fullWidth = false, bool isCount = false, bool isWeight = false}) {
    final fmt = isCount ? NumberFormat('#,##0') : NumberFormat('#,##0.00');
    final valStr = isCount ? fmt.format(value) : (isWeight ? '${fmt.format(value)} kg' : 'Rs. ${fmt.format(value)}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Text(valStr,
              style: TextStyle(
                  color: color,
                  fontSize: fullWidth ? 22 : 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double value, Color color,
      {bool bold = false}) {
    final fmt = NumberFormat('#,##0.00');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                  color: AppTheme.textPrimary)),
          Text('Rs. ${fmt.format(value.abs())}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildFarmDataTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _farmDataList.isEmpty
          ? const Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.agriculture_rounded,
                      size: 70, color: AppTheme.primaryLight),
                  SizedBox(height: 12),
                  Text('No farm records yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _farmDataList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _farmDataCard(_farmDataList[i]),
            ),
    );
  }

  Widget _farmDataCard(FarmData data) {
    final fmt = NumberFormat('#,##0.00');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(data.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ]),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppTheme.primary),
                      onPressed: () => _showAddFarmDataDialog(existing: data),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppTheme.error),
                      onPressed: () => _deleteRecord(data),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data.breed.isNotEmpty)
                  _infoChip('Breed', data.breed, Icons.pets_rounded, AppTheme.primary),
                _infoChip('Chicks', '${data.numberOfChicks}', Icons.egg_rounded,
                    AppTheme.primary),
                _infoChip('Total', 'Rs. ${fmt.format(data.totalExpense)}',
                    Icons.payments_outlined, AppTheme.error),
              ],
            ),
            const SizedBox(height: 10),
            _expenseRow('Chicks Amount', data.chicksAmount),
            if (data.medicineAmount > 0) _expenseRow('Medicine', data.medicineAmount),
            if (data.grainsAmount > 0) _expenseRow('Grains/Feed', data.grainsAmount),
            if (data.otherExpenses > 0)
              _expenseRow('Other', data.otherExpenses),
            if (data.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${data.notes}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$label: $value',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _expenseRow(String label, double value) {
    if (value == 0) return const SizedBox.shrink();
    final fmt = NumberFormat('#,##0.00');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text('Rs. ${fmt.format(value)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _deleteRecord(FarmData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content:
            const Text('Are you sure you want to delete this farm record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.deleteFarmData(data.id);
      _loadData();
    }
  }

  Future<void> _showAddFarmDataDialog({FarmData? existing}) async {
    final dateCtrl = TextEditingController(
        text:
            existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final breedCtrl = TextEditingController(text: existing?.breed ?? '');
    final chicksCtrl =
        TextEditingController(text: existing?.numberOfChicks.toString() ?? '');
    final rateCtrl = TextEditingController(
        text: existing != null && existing.numberOfChicks > 0
            ? (existing.chicksAmount / existing.numberOfChicks).toStringAsFixed(2)
            : '');
    final otherCtrl =
        TextEditingController(text: existing?.otherExpenses.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String paymentMode = existing?.paymentMode ?? 'Cash';
    const paymentMethods = ['Cash', 'Bank Transfer', 'eSewa', 'Khalti', 'Cheque', 'Other'];
    
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void updateTotals(String _) => setModalState(() {});

          double getChicksAmt() {
            final chicks = int.tryParse(chicksCtrl.text) ?? 0;
            final rate = double.tryParse(rateCtrl.text) ?? 0;
            return chicks * rate;
          }

          double getTotalExp() {
            final other = double.tryParse(otherCtrl.text) ?? 0;
            return getChicksAmt() + other;
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                        child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(existing == null ? 'Add Farm Record' : 'Edit Farm Record',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    _buildDateField(dateCtrl, ctx),
                    const SizedBox(height: 12),
                    _buildField(breedCtrl, 'Breed of Chicken', Icons.pets_rounded,
                        isNumber: false),
                    const SizedBox(height: 12),
                    _buildField(chicksCtrl, 'Number of Chicks', Icons.egg_rounded,
                        isNumber: true, onChanged: updateTotals),
                    const SizedBox(height: 12),
                    _buildField(rateCtrl, 'Rate per Chick (Rs.)',
                        Icons.payments_outlined,
                        isDecimal: true, onChanged: updateTotals),
                    const SizedBox(height: 12),
                    _buildField(otherCtrl, 'Other Expenses (Rs.)',
                        Icons.miscellaneous_services_rounded,
                        isDecimal: true, onChanged: updateTotals),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card_rounded, color: AppTheme.primary)),
                      items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setModalState(() => paymentMode = v ?? 'Cash'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          prefixIcon:
                              Icon(Icons.note_outlined, color: AppTheme.primary)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Chicks Total:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                              Text('Rs. ${NumberFormat('#,##0.00').format(getChicksAmt())}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Expense:', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                              Text('Rs. ${NumberFormat('#,##0.00').format(getTotalExp())}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.error, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final data = FarmData(
                          id: existing?.id,
                          date: dateCtrl.text,
                          breed: breedCtrl.text,
                          numberOfChicks: int.tryParse(chicksCtrl.text) ?? 0,
                          chicksAmount: getChicksAmt(),
                          medicineAmount: existing?.medicineAmount ?? 0, // Preserve old data if exists
                          grainsAmount: existing?.grainsAmount ?? 0, // Preserve old data if exists
                          otherExpenses: double.tryParse(otherCtrl.text) ?? 0,
                          notes: notesCtrl.text,
                          paymentMode: paymentMode,
                          createdAt: existing?.createdAt,
                        );
                        if (existing == null) {
                          await DatabaseService.instance.insertFarmData(data);
                        } else {
                          await DatabaseService.instance.updateFarmData(data);
                        }
                        Navigator.pop(ctx);
                        _loadData();
                      },
                      child:
                          Text(existing == null ? 'ADD RECORD' : 'UPDATE RECORD'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, bool isDecimal = false, void Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : (isNumber ? TextInputType.number : TextInputType.text),
      decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, color: AppTheme.primary)),
    );
  }

  Widget _buildDateField(TextEditingController ctrl, BuildContext ctx) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon:
              Icon(Icons.calendar_today_outlined, color: AppTheme.primary)),
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      },
    );
  }
}
