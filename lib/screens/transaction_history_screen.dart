import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _filterType = 'all'; // 'all', 'income', 'expense'

  static const _accent = Color(0xFF37474F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final rows = await DatabaseService.instance.getTransactionHistory();
    setState(() {
      _all = rows;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _filterType == 'all'
          ? _all
          : _all.where((r) => r['type'] == _filterType).toList();
    });
  }

  double get _totalIncome => _all
      .where((r) => r['type'] == 'income')
      .fold(0.0, (s, r) => s + (r['amount'] as double));

  double get _totalExpense => _all
      .where((r) => r['type'] == 'expense')
      .fold(0.0, (s, r) => s + (r['amount'] as double));

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: _accent,
        elevation: 0,
        title: const Text('Transaction History',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
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
                child: Text('${_filtered.length} records',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Summary banner ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _summaryTile('Total Received', fmt.format(_totalIncome),
                              Colors.greenAccent.shade400, Icons.arrow_downward_rounded),
                          const SizedBox(width: 12),
                          _summaryTile('Total Paid Out', fmt.format(_totalExpense),
                              Colors.redAccent.shade200, Icons.arrow_upward_rounded),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      Row(
                        children: [
                          _filterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _filterChip('Received', 'income'),
                          const SizedBox(width: 8),
                          _filterChip('Paid Out', 'expense'),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── List ────────────────────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 72,
                                  color: _accent.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              const Text('No transactions yet.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _accent,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 20, 16, 32),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _txnTile(_filtered[i], fmt),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryTile(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10)),
                  Text('Rs. $value',
                      style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    final selected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = type);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? _accent : Colors.white70),
        ),
      ),
    );
  }

  Future<void> _deleteTxn(Map<String, dynamic> txn) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This will permanently delete this transaction and adjust the associated records. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    await DatabaseService.instance.deleteTransaction(
      txn['id'],
      txn['source'],
      txn['referenceId'],
      txn['amount'],
    );
    await _load();
  }

  Widget _txnTile(Map<String, dynamic> txn, NumberFormat fmt) {
    final isIncome = txn['type'] == 'income';
    final color = isIncome ? Colors.green.shade700 : AppTheme.error;
    final bgColor = isIncome
        ? Colors.green.withOpacity(0.07)
        : AppTheme.error.withOpacity(0.06);

    IconData iconData;
    switch (txn['icon']) {
      case 'customer':
        iconData = Icons.people_alt_rounded;
        break;
      case 'labour':
        iconData = Icons.engineering_rounded;
        break;
      case 'medicine':
        iconData = Icons.medication_liquid_rounded;
        break;
      case 'feed':
        iconData = Icons.grass_rounded;
        break;
      case 'farm':
        iconData = Icons.agriculture_rounded;
        break;
      default:
        iconData = Icons.receipt_rounded;
    }

    return GestureDetector(
      onLongPress: () => _deleteTxn(txn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(iconData, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // Title + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['title'],
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(txn['date'],
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card_rounded,
                              size: 10, color: color),
                          const SizedBox(width: 3),
                          Text(txn['paymentMode'],
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'} Rs. ${fmt.format(txn['amount'])}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              const SizedBox(height: 2),
              Text(isIncome ? 'Received' : 'Paid',
                  style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    ));
  }
}
