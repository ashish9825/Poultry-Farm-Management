import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/app_theme.dart';
import '../models/customer_model.dart';
import '../models/labour_model.dart';
import '../models/farm_data_model.dart';
import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, double> _summary = {};
  List<Customer> _customers = [];
  List<Labour> _labours = [];
  List<FarmData> _farmData = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final db = DatabaseService.instance;
    final results = await Future.wait([
      db.getSummary(),
      db.getCustomers(),
      db.getLabours(),
      db.getFarmData(),
    ]);
    setState(() {
      _summary = results[0] as Map<String, double>;
      _customers = results[1] as List<Customer>;
      _labours = results[2] as List<Labour>;
      _farmData = results[3] as List<FarmData>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Backup'),
        actions: [
          if (_isExporting)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: _onMenuSelected,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'export_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf_rounded, color: Colors.red), title: Text('Export PDF Backup'))),
                const PopupMenuItem(value: 'export_excel', child: ListTile(leading: Icon(Icons.table_view_rounded, color: Colors.green), title: Text('Export Excel Backup'))),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Financial Overview'),
                    const SizedBox(height: 12),
                    _buildFinancialChart(),
                    const SizedBox(height: 20),
                    _sectionTitle('Quick Stats'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _sectionTitle('Top Customers by Amount'),
                    const SizedBox(height: 12),
                    _buildTopCustomers(),
                    const SizedBox(height: 20),
                    _sectionTitle('Pending Customer Payments (Receivables)'),
                    const SizedBox(height: 12),
                    _buildPendingCustomers(),
                    const SizedBox(height: 20),
                    _sectionTitle('Pending Labour Wages (Payables)'),
                    const SizedBox(height: 12),
                    _buildPendingLabours(),
                    const SizedBox(height: 20),
                    _sectionTitle('Farm Expenses Breakdown'),
                    const SizedBox(height: 12),
                    _buildFarmExpenseBreakdown(),
                    const SizedBox(height: 20),
                    _sectionTitle('Backup & Export'),
                    const SizedBox(height: 12),
                    _buildBackupSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _buildFinancialChart() {
    final income = _summary['income'] ?? 0;
    final expense = _summary['expense'] ?? 0;
    final profit = _summary['profit'] ?? 0;
    final isProfit = profit >= 0;
    final maxVal = [income, expense].reduce((a, b) => a > b ? a : b);

    if (income == 0 && expense == 0) {
      return _emptyCard('No financial data yet');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final labels = ['Income', 'Expense', 'Profit/Loss'];
                        final fmt = NumberFormat('#,##0');
                        return BarTooltipItem(
                          '${labels[group.x]}\nRs. ${fmt.format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = ['Income', 'Expense', 'Net'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(titles[value.toInt()], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _bar(0, income, Colors.green),
                    _bar(1, expense, AppTheme.error),
                    _bar(2, profit.abs(), isProfit ? AppTheme.primary : Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend('Income', Colors.green),
                const SizedBox(width: 16),
                _legend('Expense', AppTheme.error),
                const SizedBox(width: 16),
                _legend(isProfit ? 'Profit' : 'Loss', isProfit ? AppTheme.primary : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) => BarChartGroupData(
    x: x,
    barRods: [BarChartRodData(toY: y.abs(), color: color, width: 40, borderRadius: BorderRadius.circular(6))],
  );

  Widget _legend(String label, Color color) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ],
  );

  Widget _buildStatsGrid() {
    final fmt = NumberFormat('#,##0');
    final pendingCustomers = _customers.where((c) => c.remainingAmount > 0).length;
    final pendingLabour = _labours.where((l) => l.remainingPayment > 0).length;
    final totalChicks = _farmData.fold<int>(0, (sum, f) => sum + f.numberOfChicks);

    final stats = [
      _StatItem('Customers', '${_customers.length}', Icons.people_alt_rounded, const Color(0xFF1565C0)),
      _StatItem('Labour', '${_labours.length}', Icons.engineering_rounded, const Color(0xFF6A1B9A)),
      _StatItem('Pending Payments', '$pendingCustomers customers', Icons.pending_actions_rounded, AppTheme.error),
      _StatItem('Labour Pending', '$pendingLabour workers', Icons.money_off_rounded, Colors.orange),
      _StatItem('Total Chicks', fmt.format(totalChicks), Icons.egg_rounded, AppTheme.primary),
      _StatItem('Farm Records', '${_farmData.length}', Icons.agriculture_rounded, Colors.teal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: stats.length,
      itemBuilder: (ctx, i) {
        final s = stats[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: s.color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: s.color.withOpacity(0.2))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.icon, color: s.color, size: 22),
              const SizedBox(height: 6),
              Text(s.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: s.color)),
              Text(s.label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopCustomers() {
    if (_customers.isEmpty) return _emptyCard('No customers yet');
    final sorted = [..._customers]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final top = sorted.take(5).toList();
    final fmt = NumberFormat('#,##0.00');
    return Card(
      child: Column(
        children: top.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.chickenWeight} kg @ Rs. ${fmt.format(c.chickenRate)}/kg'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${fmt.format(c.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
                if (c.remainingAmount > 0)
                  Text('Pending: Rs. ${fmt.format(c.remainingAmount)}', style: const TextStyle(color: AppTheme.error, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingCustomers() {
    final pending = _customers.where((c) => c.remainingAmount > 0).toList();
    if (pending.isEmpty) return _emptyCard('No pending customer payments');
    pending.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    
    final fmt = NumberFormat('#,##0.00');
    return Card(
      child: Column(
        children: pending.map((c) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A1565C0),
              child: Icon(Icons.person, color: Color(0xFF1565C0), size: 20),
            ),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text('Rs. ${fmt.format(c.remainingAmount)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.error)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingLabours() {
    final pending = _labours.where((l) => l.remainingPayment > 0).toList();
    if (pending.isEmpty) return _emptyCard('No pending labour payments');
    pending.sort((a, b) => b.remainingPayment.compareTo(a.remainingPayment));
    
    final fmt = NumberFormat('#,##0.00');
    return Card(
      child: Column(
        children: pending.map((l) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1A6A1B9A),
              child: Icon(Icons.engineering, color: Color(0xFF6A1B9A), size: 20),
            ),
            title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text('Rs. ${fmt.format(l.remainingPayment)}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFarmExpenseBreakdown() {
    if (_farmData.isEmpty) return _emptyCard('No farm data yet');
    double chicks = 0, medicine = 0, grains = 0, other = 0;
    for (final f in _farmData) {
      chicks += f.chicksAmount;
      medicine += f.medicineAmount;
      grains += f.grainsAmount;
      other += f.otherExpenses;
    }
    final total = chicks + medicine + grains + other;
    if (total == 0) return _emptyCard('No expense data yet');
    final fmt = NumberFormat('#,##0.00');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: [
                    if (chicks > 0) PieChartSectionData(value: chicks, color: AppTheme.primary, title: '', radius: 45),
                    if (medicine > 0) PieChartSectionData(value: medicine, color: Colors.blue, title: '', radius: 45),
                    if (grains > 0) PieChartSectionData(value: grains, color: Colors.orange, title: '', radius: 45),
                    if (other > 0) PieChartSectionData(value: other, color: Colors.purple, title: '', radius: 45),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chicks > 0) _pieRow('Chicks', chicks, total, AppTheme.primary, fmt),
                  if (medicine > 0) _pieRow('Medicine', medicine, total, Colors.blue, fmt),
                  if (grains > 0) _pieRow('Grains', grains, total, Colors.orange, fmt),
                  if (other > 0) _pieRow('Other', other, total, Colors.purple, fmt),
                  const Divider(),
                  _pieRow('Total', total, total, AppTheme.textPrimary, fmt, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pieRow(String label, double amount, double total, Color color, NumberFormat fmt, {bool bold = false}) {
    final pct = total > 0 ? (amount / total * 100).toStringAsFixed(0) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (!bold) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: bold ? AppTheme.textPrimary : AppTheme.textSecondary))),
          Text('Rs. ${fmt.format(amount)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          if (!bold) Text(' ($pct%)', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Column(
      children: [
        _backupTile(
          icon: Icons.picture_as_pdf_rounded,
          color: AppTheme.error,
          title: 'Export Full Backup (PDF)',
          subtitle: 'Comprehensive visual report of farm operations',
          onTap: () => _onMenuSelected('export_pdf'),
        ),
        const SizedBox(height: 10),
        _backupTile(
          icon: Icons.table_view_rounded,
          color: Colors.green,
          title: 'Export Full Backup (Excel)',
          subtitle: 'Spreadsheet of all data categorized in sheets',
          onTap: () => _onMenuSelected('export_excel'),
        ),
      ],
    );
  }

  Widget _backupTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            Icon(Icons.share_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary))),
    ),
  );

  Future<void> _onMenuSelected(String value) async {
    setState(() => _isExporting = true);
    try {
      switch (value) {
        case 'export_pdf':
          final path = await BackupService.exportFullPDF();
          await _shareFile(path, 'Poultry Farm Full Backup (PDF)');
          break;
        case 'export_excel':
          final path = await BackupService.exportFullExcel();
          await _shareFile(path, 'Poultry Farm Database (Excel)');
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _shareFile(String path, String title) async {
    final file = XFile(path);
    await Share.shareXFiles([file], text: '$title - ${DateFormat('dd MMM yyyy').format(DateTime.now())}');
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}
