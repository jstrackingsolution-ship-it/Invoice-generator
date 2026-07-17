import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/receipt.dart';
import '../utils/pdf_generator.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptPreviewScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(receipt.receiptNumber)),
      body: PdfPreview(
        build: (format) => InvoicePdfGenerator.generateReceipt(receipt),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '${receipt.receiptNumber}.pdf',
      ),
    );
  }
}
