import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/dead_chicks_model.dart';

class DeadChicksScreen extends StatefulWidget {
  const DeadChicksScreen({super.key});
  @override
  State<DeadChicksScreen> createState() => _DeadChicksScreenState();
}

class _DeadChicksScreenState extends State<DeadChicksScreen> {
  List<DeadChicks> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DatabaseService.instance.getDeadChicks();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Dead Chicks'),
        backgroundColor: const Color(0xFFD32F2F),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : _records.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.warning_amber_rounded, size: 70, color: Color(0xFFD32F2F)),
                  SizedBox(height: 12),
                  Text('No dead chicks records', style: TextStyle(color: AppTheme.textSecondary)),
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
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _recordCard(DeadChicks record) {
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
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 6),
                  Text(record.date, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD32F2F))),
                ]),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFFD32F2F)),
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
                const Icon(Icons.pets, size: 20, color: Color(0xFFD32F2F)),
                const SizedBox(width: 8),
                Text('Count: ${record.count}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
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

  Future<void> _deleteRecord(DeadChicks record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.deleteDeadChicks(record.id);
      _loadRecords();
    }
  }

  Future<void> _openForm({DeadChicks? existing}) async {
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController(text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final countCtrl = TextEditingController(text: existing?.count.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(existing == null ? 'Add Dead Chicks' : 'Edit Record', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFFD32F2F))),
                  onTap: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Number of Dead Chicks', prefixIcon: Icon(Icons.numbers, color: Color(0xFFD32F2F))),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note_alt_outlined, color: Color(0xFFD32F2F))),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final data = DeadChicks(
                      id: existing?.id,
                      date: dateCtrl.text,
                      count: int.tryParse(countCtrl.text) ?? 0,
                      notes: notesCtrl.text,
                      createdAt: existing?.createdAt,
                    );
                    if (existing == null) {
                      await DatabaseService.instance.insertDeadChicks(data);
                    } else {
                      await DatabaseService.instance.updateDeadChicks(data);
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
    );
  }
}
