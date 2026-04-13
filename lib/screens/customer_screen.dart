import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/customer_model.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<Customer> _customers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

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

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _customers : _customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.symbolNumber.toLowerCase().contains(q) ||
        c.mobileNo.contains(q)
      ).toList();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await DatabaseService.instance.getCustomers();
    setState(() {
      _customers = customers;
      _filtered = customers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Customers'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${_customers.length} total', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, symbol or mobile...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                fillColor: Colors.white.withOpacity(0.2),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.people_outline, size: 70, color: Color(0xFF1565C0)),
                        const SizedBox(height: 12),
                        Text(_searchCtrl.text.isEmpty ? 'No customers yet' : 'No results found', style: const TextStyle(color: AppTheme.textSecondary)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _customerCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerForm(),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _customerCard(Customer customer) {
    final fmt = NumberFormat('#,##0.00');
    final hasRemaining = customer.remainingAmount > 0;
    return Card(
      child: InkWell(
        onTap: () => _viewCustomerDetail(customer),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      image: customer.imagePath != null && File(customer.imagePath!).existsSync()
                          ? DecorationImage(image: FileImage(File(customer.imagePath!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: customer.imagePath == null ? const Icon(Icons.person, color: Color(0xFF1565C0)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.tag, size: 12, color: AppTheme.textSecondary),
                          Text(customer.symbolNumber, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 2),
                          Text(customer.date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasRemaining ? AppTheme.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasRemaining ? 'Pending' : 'Paid',
                      style: TextStyle(color: hasRemaining ? AppTheme.error : Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  _miniStat('Weight', '${customer.chickenWeight} kg', Icons.scale_outlined),
                  _miniStat('Rate', 'Rs. ${fmt.format(customer.chickenRate)}/kg', Icons.price_change_outlined),
                  _miniStat('Total', 'Rs. ${fmt.format(customer.totalAmount)}', Icons.payments_outlined),
                ],
              ),
              if (hasRemaining) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining:', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                      Text('Rs. ${fmt.format(customer.remainingAmount)}', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (customer.average > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avg Weight per Bird:', style: TextStyle(color: Color(0xFF1565C0), fontSize: 13)),
                      Text('${fmt.format(customer.average)} kg', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openCustomerForm(existing: customer),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteCustomer(customer),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _viewCustomerDetail(Customer c) {
    final fmt = NumberFormat('#,##0.00');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      image: c.imagePath != null && File(c.imagePath!).existsSync()
                          ? DecorationImage(image: FileImage(File(c.imagePath!)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: c.imagePath == null ? const Icon(Icons.person, color: Color(0xFF1565C0), size: 36) : null,
                  ),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('# ${c.symbolNumber}', style: const TextStyle(color: AppTheme.textSecondary)),
                    Text(c.mobileNo, style: const TextStyle(color: AppTheme.textSecondary)),
                  ]),
                ],
              ),
              const Divider(height: 28),
              _detailRow('Date', c.date),
              _detailRow('Address', c.address),
              if (c.numberOfChicks > 0) _detailRow('Number of Chicks', '${c.numberOfChicks}'),
              _detailRow('Chicken Weight', '${c.chickenWeight} kg'),
              _detailRow('Chicken Rate', 'Rs. ${fmt.format(c.chickenRate)}/kg'),
              _detailRow('Average', 'Rs. ${fmt.format(c.average)}'),
              _detailRow('Total Amount', 'Rs. ${fmt.format(c.totalAmount)}', highlight: true),
              _detailRow('Deposit Amount', 'Rs. ${fmt.format(c.depositAmount)}'),
              _detailRow('Remaining', 'Rs. ${fmt.format(c.remainingAmount)}', highlight: c.remainingAmount > 0),
              _detailRow('Payment Mode', c.paymentMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500, color: highlight ? AppTheme.error : AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"? This will also remove associated income records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.deleteCustomer(customer.id);
      _loadCustomers();
    }
  }

  Future<void> _openCustomerForm({Customer? existing}) async {
    final formKey = GlobalKey<FormState>();
    final symbolCtrl = TextEditingController(text: existing?.symbolNumber ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dateCtrl = TextEditingController(text: existing?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final mobileCtrl = TextEditingController(text: existing?.mobileNo ?? '');
    final chicksCtrl = TextEditingController(text: (existing != null && existing.numberOfChicks > 0) ? existing.numberOfChicks.toString() : '');
    final weightCtrl = TextEditingController(text: existing?.chickenWeight.toString() ?? '');
    final rateCtrl = TextEditingController(text: existing?.chickenRate.toString() ?? '');
    final depositCtrl = TextEditingController(text: existing?.depositAmount.toString() ?? '');
    String paymentMode = existing?.paymentMode ?? 'Cash';
    String? imagePath = existing?.imagePath;

    final calc = ValueNotifier<String>('');
    void recalculate() {
      final cVal = int.tryParse(chicksCtrl.text) ?? 0;
      final w = double.tryParse(weightCtrl.text) ?? 0;
      final r = double.tryParse(rateCtrl.text) ?? 0;
      final d = double.tryParse(depositCtrl.text) ?? 0;
      final total = w * r;
      final remaining = total - d;
      final avg = cVal > 0 ? w / cVal : 0.0;
      
      calc.value = 'Total: Rs. ${NumberFormat('#,##0.00').format(total)}  |  Remaining: Rs. ${NumberFormat('#,##0.00').format(remaining)}\nAverage: ${NumberFormat('#,##0.00').format(avg)} kg per bird';
    }
    weightCtrl.addListener(recalculate);
    rateCtrl.addListener(recalculate);
    depositCtrl.addListener(recalculate);
    chicksCtrl.addListener(recalculate);

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
                  Text(existing == null ? 'Add Customer' : 'Edit Customer', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  // Image picker
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery);
                        if (img != null) setModalState(() => imagePath = img.path);
                      },
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF1565C0), width: 2),
                          image: imagePath != null && File(imagePath!).existsSync()
                              ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: imagePath == null ? const Icon(Icons.add_a_photo_outlined, color: Color(0xFF1565C0), size: 32) : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(child: Text('Tap to add photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                  const SizedBox(height: 16),

                  _field(symbolCtrl, 'Symbol/Token Number', Icons.tag, required: true),
                  const SizedBox(height: 12),
                  _field(nameCtrl, 'Customer Name', Icons.person_outline, required: true),
                  const SizedBox(height: 12),
                  _dateField(dateCtrl, ctx),
                  const SizedBox(height: 12),
                  _field(addressCtrl, 'Address', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _field(mobileCtrl, 'Mobile Number', Icons.phone_outlined, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field(chicksCtrl, 'Number of Chicks', Icons.pets_outlined, keyboard: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(weightCtrl, 'Chicken Weight (kg)', Icons.scale_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true), required: true),
                  const SizedBox(height: 12),
                  _field(rateCtrl, 'Rate per kg (Rs.)', Icons.price_change_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true), required: true),
                  const SizedBox(height: 12),
                  _field(depositCtrl, 'Deposit Amount (Rs.)', Icons.payments_outlined, keyboard: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payment, color: Color(0xFF1565C0))),
                    items: ['Cash', 'Bank Transfer', 'Mobile Banking', 'Credit', 'Cheque']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setModalState(() => paymentMode = v!),
                  ),
                  const SizedBox(height: 12),
                  // Auto calculation
                  ValueListenableBuilder<String>(
                    valueListenable: calc,
                    builder: (_, val, __) => val.isEmpty ? const SizedBox.shrink() : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(val, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final customer = Customer(
                        id: existing?.id,
                        symbolNumber: symbolCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        date: dateCtrl.text,
                        imagePath: imagePath,
                        address: addressCtrl.text.trim(),
                        mobileNo: mobileCtrl.text.trim(),
                        numberOfChicks: int.tryParse(chicksCtrl.text) ?? 0,
                        chickenWeight: double.tryParse(weightCtrl.text) ?? 0,
                        chickenRate: double.tryParse(rateCtrl.text) ?? 0,
                        depositAmount: double.tryParse(depositCtrl.text) ?? 0,
                        paymentMode: paymentMode,
                        createdAt: existing?.createdAt,
                      );
                      if (existing == null) {
                        await DatabaseService.instance.insertCustomer(customer);
                      } else {
                        await DatabaseService.instance.updateCustomer(customer);
                      }
                      Navigator.pop(ctx);
                      _loadCustomers();
                    },
                    child: Text(existing == null ? 'ADD CUSTOMER' : 'UPDATE CUSTOMER'),
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
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF1565C0))),
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _dateField(TextEditingController ctrl, BuildContext ctx) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_outlined, color: Color(0xFF1565C0))),
      onTap: () async {
        final picked = await showDatePicker(context: ctx, initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      },
    );
  }
}
