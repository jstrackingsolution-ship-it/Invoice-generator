import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../providers/company_profile_provider.dart';
import '../providers/invoice_provider.dart';
import '../utils/formatters.dart';
import '../utils/month_utils.dart';
import 'invoice_preview_screen.dart';

const List<int> _gpsMonthOptions = [1, 2, 3, 6, 12];

class InvoiceFormScreen extends StatefulWidget {
  final Invoice? existingInvoice;

  const InvoiceFormScreen({super.key, this.existingInvoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Invoice _invoice;

  // Controllers for simple text fields
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyAddressCtrl;
  late TextEditingController _companyEmailCtrl;
  late TextEditingController _companyPhoneCtrl;
  late TextEditingController _companyTinCtrl;
  late TextEditingController _companyVrnCtrl;
  late TextEditingController _clientNameCtrl;
  late TextEditingController _clientEmailCtrl;
  late TextEditingController _clientPhoneCtrl;
  late TextEditingController _clientAddressCtrl;
  late TextEditingController _clientVrnCtrl;
  late TextEditingController _clientTinCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;

  bool get _isEditing => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<InvoiceProvider>();

    if (_isEditing) {
      // Work on a shallow copy so cancelling the form doesn't mutate state.
      final src = widget.existingInvoice!;
      _invoice = Invoice(
        id: src.id,
        invoiceNumber: src.invoiceNumber,
        companyName: src.companyName,
        companyAddress: src.companyAddress,
        companyEmail: src.companyEmail,
        companyPhone: src.companyPhone,
        companyTin: src.companyTin,
        companyVrn: src.companyVrn,
        companyLogoBase64: src.companyLogoBase64,
        client: Client(
          name: src.client.name,
          email: src.client.email,
          phone: src.client.phone,
          address: src.client.address,
          vrn: src.client.vrn,
          tin: src.client.tin,
        ),
        items: src.items
            .map((i) => InvoiceItem(
                description: i.description,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                months: i.months))
            .toList(),
        issueDate: src.issueDate,
        dueDate: src.dueDate,
        notes: src.notes,
        taxRate: src.taxRate,
        discount: src.discount,
        template: src.template,
        status: src.status,
        paidDate: src.paidDate,
        serviceType: src.serviceType,
        monthsPaid: src.monthsPaid,
      );
    } else {
      final profile = context.read<CompanyProfileProvider>().profile;
      _invoice = Invoice(
        invoiceNumber: provider.generateNextInvoiceNumber(),
        companyName: profile.name,
        companyAddress: profile.address,
        companyEmail: profile.email,
        companyPhone: profile.phone,
        companyTin: profile.tinNumber,
        companyVrn: profile.vrnNumber,
        companyLogoBase64: profile.logoBase64,
      );
    }

    _companyNameCtrl = TextEditingController(text: _invoice.companyName);
    _companyAddressCtrl = TextEditingController(text: _invoice.companyAddress);
    _companyEmailCtrl = TextEditingController(text: _invoice.companyEmail);
    _companyPhoneCtrl = TextEditingController(text: _invoice.companyPhone);
    _companyTinCtrl = TextEditingController(text: _invoice.companyTin);
    _companyVrnCtrl = TextEditingController(text: _invoice.companyVrn);
    _clientNameCtrl = TextEditingController(text: _invoice.client.name);
    _clientEmailCtrl = TextEditingController(text: _invoice.client.email);
    _clientPhoneCtrl = TextEditingController(text: _invoice.client.phone);
    _clientAddressCtrl = TextEditingController(text: _invoice.client.address);
    _clientVrnCtrl = TextEditingController(text: _invoice.client.vrn);
    _clientTinCtrl = TextEditingController(text: _invoice.client.tin);
    _notesCtrl = TextEditingController(text: _invoice.notes);
    _taxCtrl = TextEditingController(text: _invoice.taxRate == 0 ? '' : _invoice.taxRate.toString());
    _discountCtrl =
        TextEditingController(text: _invoice.discount == 0 ? '' : _invoice.discount.toString());
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyAddressCtrl.dispose();
    _companyEmailCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyTinCtrl.dispose();
    _companyVrnCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientVrnCtrl.dispose();
    _clientTinCtrl.dispose();
    _notesCtrl.dispose();
    _taxCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _invoice.issueDate : _invoice.dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _invoice.issueDate = picked;
        } else {
          _invoice.dueDate = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() => _invoice.items.add(InvoiceItem()));
  }

  void _removeItem(int index) {
    if (_invoice.items.length == 1) return;
    setState(() => _invoice.items.removeAt(index));
  }

  void _syncStringFieldsIntoInvoice() {
    _invoice.companyName = _companyNameCtrl.text.trim();
    _invoice.companyAddress = _companyAddressCtrl.text.trim();
    _invoice.companyEmail = _companyEmailCtrl.text.trim();
    _invoice.companyPhone = _companyPhoneCtrl.text.trim();
    _invoice.companyTin = _companyTinCtrl.text.trim();
    _invoice.companyVrn = _companyVrnCtrl.text.trim();
    _invoice.client.name = _clientNameCtrl.text.trim();
    _invoice.client.email = _clientEmailCtrl.text.trim();
    _invoice.client.phone = _clientPhoneCtrl.text.trim();
    _invoice.client.address = _clientAddressCtrl.text.trim();
    _invoice.client.vrn = _clientVrnCtrl.text.trim();
    _invoice.client.tin = _clientTinCtrl.text.trim();
    _invoice.notes = _notesCtrl.text.trim();
    _invoice.taxRate = double.tryParse(_taxCtrl.text.trim()) ?? 0;
    _invoice.discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
  }

  Future<void> _save({bool preview = false}) async {
    if (!_formKey.currentState!.validate()) return;
    _syncStringFieldsIntoInvoice();

    final provider = context.read<InvoiceProvider>();
    if (_isEditing) {
      await provider.updateInvoice(_invoice);
    } else {
      await provider.addInvoice(_invoice);
    }

    if (!mounted) return;

    if (preview) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: _invoice)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'New Invoice'),
        actions: [
          TextButton(
            onPressed: () => _save(preview: true),
            child: const Text('Preview', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _sectionTitle('Invoice Details'),
            _readOnlyRow('Invoice Number', _invoice.invoiceNumber),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _dateTile('Issue Date', _invoice.issueDate, () => _pickDate(isIssueDate: true))),
                const SizedBox(width: 10),
                Expanded(child: _dateTile('Due Date', _invoice.dueDate, () => _pickDate(isIssueDate: false))),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<InvoiceStatus>(
              value: _invoice.status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: InvoiceStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _invoice.status = v ?? _invoice.status),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Template'),
            _templatePicker(),

            const SizedBox(height: 24),
            _sectionTitle('Service Type'),
            _serviceTypePicker(),
            if (_invoice.serviceType == ServiceType.gpsService) ...[
              const SizedBox(height: 12),
              _gpsServiceSection(),
            ],

            const SizedBox(height: 24),
            _sectionTitle('From (Your Business)'),
            _textField(_companyNameCtrl, 'Company Name', validator: _requiredValidator),
            _textField(_companyAddressCtrl, 'Address'),
            _textField(_companyEmailCtrl, 'Email'),
            _textField(_companyPhoneCtrl, 'Phone'),
            _textField(_companyTinCtrl, 'TIN Number'),
            _textField(_companyVrnCtrl, 'VRN Number'),

            const SizedBox(height: 24),
            _sectionTitle('Bill To (Client)'),
            _textField(_clientNameCtrl, 'Client Name', validator: _requiredValidator),
            _textField(_clientAddressCtrl, 'Address'),
            _textField(_clientEmailCtrl, 'Email'),
            _textField(_clientPhoneCtrl, 'Phone'),
            _textField(_clientVrnCtrl, 'VRN Number'),
            _textField(_clientTinCtrl, 'TIN Number'),

            const SizedBox(height: 24),
            _sectionTitle('Line Items'),
            ..._invoice.items.asMap().entries.map((e) => _itemRow(e.key, e.value)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Discount %', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _taxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tax %', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _textField(_notesCtrl, 'Notes (payment terms, thank you note, etc.)', maxLines: 3),

            const SizedBox(height: 20),
            _totalsSummary(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _save(),
            icon: const Icon(Icons.save),
            label: Text(_isEditing ? 'Update Invoice' : 'Save Invoice'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _readOnlyRow(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value),
          ],
        ),
      );

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          child: Text(Formatters.date(date)),
        ),
      );

  Widget _textField(TextEditingController controller, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }

  Widget _templatePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: InvoiceTemplate.values.map((t) {
        final selected = _invoice.template == t;
        return ChoiceChip(
          label: Text(t.label),
          selected: selected,
          onSelected: (_) => setState(() => _invoice.template = t),
        );
      }).toList(),
    );
  }

  Widget _serviceTypePicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ServiceType.values.map((t) {
        final selected = _invoice.serviceType == t;
        return ChoiceChip(
          label: Text(t.label),
          selected: selected,
          onSelected: (_) => setState(() => _invoice.serviceType = t),
        );
      }).toList(),
    );
  }

  Widget _gpsServiceSection() {
    final expiry = addMonths(_invoice.issueDate, _invoice.monthsPaid);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GPS Service Charge Details',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _invoice.monthsPaid,
            decoration: const InputDecoration(
                labelText: 'Number of Months Paid',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white),
            items: _gpsMonthOptions
                .map((m) => DropdownMenuItem(value: m, child: Text('$m month${m == 1 ? '' : 's'}')))
                .toList(),
            onChanged: (v) => setState(() => _invoice.monthsPaid = v ?? _invoice.monthsPaid),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_available, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text('Expires on: ${Formatters.date(expiry)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int index, InvoiceItem item) {
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextFormField(
              initialValue: item.description,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              onChanged: (v) => item.description = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity == 0 ? '' : item.quantity.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => item.quantity = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice == 0 ? '' : item.unitPrice.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.months.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Month(s)', border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => item.months = int.tryParse(v) ?? 1),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Total: ${Formatters.money(item.total)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _summaryLine('Subtotal', Formatters.money(_invoice.subtotal)),
          _summaryLine('Discount', '- ${Formatters.money(_invoice.discountAmount)}'),
          _summaryLine('Tax', Formatters.money(_invoice.taxAmount)),
          const Divider(),
          _summaryLine('Total', Formatters.money(_invoice.total), bold: true),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
