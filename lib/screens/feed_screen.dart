import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/feed_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Feed> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DatabaseService.instance.getFeeds();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Feed Grains'),
        backgroundColor: const Color(0xFFE65100),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${_records.length} total', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : _records.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.grass_rounded, size: 70, color: Color(0xFFE65100)),
                  SizedBox(height: 12),
                  Text('No feed records found', style: TextStyle(color: AppTheme.textSecondary)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _recordCard(_records[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _recordCard(Feed record) {
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
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Text(record.date, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                ]),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFFE65100)),
                      onPressed: () => _openForm(existing: record),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                      onPressed: () => _deleteRecord(record),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Icons.grass_outlined, size: 20, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(child: Text(record.type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text('Quantity: ${record.quantity} kg', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Text('Rs. ${NumberFormat('#,##0.00').format(record.cost)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.credit_card_rounded, size: 12, color: Color(0xFFE65100)),
                  const SizedBox(width: 4),
                  Text('Via ${record.paymentMode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
                ],
              ),
            ),
            if (record.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: ${record.notes}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(Feed record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record? This will also remove the associated expense.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.deleteFeed(record.id);
      _loadRecords();
    }
  }

  Future<void> _openForm({Feed? existing}) async {
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController(text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final typeCtrl = TextEditingController(text: existing?.type ?? '');
    final qtyCtrl = TextEditingController(text: existing?.quantity.toString() ?? '');
    final costCtrl = TextEditingController(text: existing?.cost.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String paymentMode = existing?.paymentMode ?? 'Cash';
    const paymentMethods = ['Cash', 'Bank Transfer', 'eSewa', 'Khalti', 'Cheque', 'Other'];

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
                  Text(existing == null ? 'Add Feed Grains' : 'Edit Feed Grains', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFFE65100))),
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: 'Feed Type (e.g. Starter, Grower)', prefixIcon: Icon(Icons.grass_outlined, color: Color(0xFFE65100))),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity (kg)', prefixIcon: Icon(Icons.scale_outlined, color: Color(0xFFE65100))),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Total Cost (Rs.)', prefixIcon: Icon(Icons.payments_outlined, color: Color(0xFFE65100))),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.credit_card_rounded, color: Color(0xFFE65100))),
                    items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setModalState(() => paymentMode = v ?? 'Cash'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note_alt_outlined, color: Color(0xFFE65100))),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final data = Feed(
                        id: existing?.id,
                        date: dateCtrl.text,
                        type: typeCtrl.text,
                        quantity: double.tryParse(qtyCtrl.text) ?? 0,
                        cost: double.tryParse(costCtrl.text) ?? 0,
                        notes: notesCtrl.text,
                        paymentMode: paymentMode,
                        createdAt: existing?.createdAt,
                      );
                      if (existing == null) {
                        await DatabaseService.instance.insertFeed(data);
                      } else {
                        await DatabaseService.instance.updateFeed(data);
                      }
                      Navigator.pop(ctx);
                      _loadRecords();
                    },
                    child: Text(existing == null ? 'ADD RECORD' : 'UPDATE RECORD'),
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
}
