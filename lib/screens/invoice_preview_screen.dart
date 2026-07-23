import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../models/receipt.dart';
import '../providers/invoice_provider.dart';
import '../providers/receipt_provider.dart';
import '../utils/formatters.dart';
import '../utils/pdf_generator.dart';
import 'receipt_preview_screen.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late InvoiceTemplate _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.invoice.template;
  }

  Future<void> _applyTemplateChoice() async {
    if (_selectedTemplate == widget.invoice.template) return;
    widget.invoice.template = _selectedTemplate;
    await context.read<InvoiceProvider>().updateInvoice(widget.invoice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template set to ${_selectedTemplate.label}')),
      );
    }
  }

  Future<void> _markAsPaidAndGenerateReceipt() async {
    final method = await showDialog<PaymentMethod>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Mark as Paid'),
        children: PaymentMethod.values
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, m),
                  child: Text(m.label),
                ))
            .toList(),
      ),
    );
    if (method == null) return;

    final invoice = widget.invoice;
    final invoiceProvider = context.read<InvoiceProvider>();
    final receiptProvider = context.read<ReceiptProvider>();

    await invoiceProvider.markPaid(invoice.id);

    final receipt = Receipt(
      receiptNumber: receiptProvider.generateNextReceiptNumber(),
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      companyName: invoice.companyName,
      companyLogoBase64: invoice.companyLogoBase64,
      companyTin: invoice.companyTin,
      companyVrn: invoice.companyVrn,
      clientName: invoice.client.name,
      clientTin: invoice.client.tin,
      clientVrn: invoice.client.vrn,
      amountPaid: invoice.total,
      datePaid: invoice.paidDate ?? DateTime.now(),
      method: method,
      items: invoice.items,
      subtotal: invoice.taxableAmount,
      taxRate: invoice.taxRate,
      taxAmount: invoice.taxAmount,
      monthsPaid: invoice.isGpsService ? invoice.monthsPaid : null,
      serviceExpiry: invoice.isGpsService ? invoice.serviceExpiry : null,
    );
    await receiptProvider.addReceipt(receipt);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(receipt: receipt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final alreadyPaid = invoice.status == InvoiceStatus.paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          if (!alreadyPaid)
            TextButton.icon(
              onPressed: _markAsPaidAndGenerateReceipt,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Mark Paid', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (invoice.isGpsService && invoice.serviceExpiry != null)
            _GpsExpiryBanner(invoice: invoice),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Template: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: InvoiceTemplate.values.map((t) {
                      final selected = _selectedTemplate == t;
                      return ChoiceChip(
                        label: Text(t.label),
                        selected: selected,
                        onSelected: (_) async {
                          setState(() => _selectedTemplate = t);
                          await _applyTemplateChoice();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: PdfPreview(
              key: ValueKey(_selectedTemplate),
              build: (format) => InvoicePdfGenerator.generate(invoice, _selectedTemplate),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: '${invoice.invoiceNumber}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsExpiryBanner extends StatelessWidget {
  final Invoice invoice;

  const _GpsExpiryBanner({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final expiry = invoice.serviceExpiry!;
    final expired = invoice.isServiceExpired;
    final color = expired ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS Service — paid ${invoice.monthsPaid} month(s) • '
              '${expired ? 'Expired' : 'Expires'} ${Formatters.date(expiry)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
