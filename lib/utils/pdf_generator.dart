import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../models/receipt.dart';
import 'formatters.dart';
import 'number_to_words.dart';

/// Builds a ready-to-print/share PDF for an [Invoice] in the chosen
/// [InvoiceTemplate] style. Each template has a distinct look but is fed
/// from the exact same invoice data.
class InvoicePdfGenerator {
  static Future<Uint8List> generate(
    Invoice invoice,
    InvoiceTemplate template, {
    bool showAmountInWords = true,
  }) async {
    final doc = pw.Document();

    switch (template) {
      case InvoiceTemplate.classic:
        _buildClassic(doc, invoice, showAmountInWords);
        break;
      case InvoiceTemplate.modern:
        _buildModern(doc, invoice, showAmountInWords);
        break;
      case InvoiceTemplate.minimal:
        _buildMinimal(doc, invoice, showAmountInWords);
        break;
    }

    return doc.save();
  }

  /// Builds a clean payment receipt PDF for a [Receipt], stamped PAID.
  static Future<Uint8List> generateReceipt(
    Receipt receipt, {
    bool showAmountInWords = true,
  }) async {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF1B8A5A); // green, distinct from invoice accent
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final logo = _logoImage(receipt.companyLogoBase64, size: 44);

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(children: [
                  if (logo != null) ...[logo, pw.SizedBox(width: 10)],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(receipt.companyName,
                          style: pw.TextStyle(font: boldFont, fontSize: 18)),
                      if (receipt.companyTin != null && receipt.companyTin!.isNotEmpty)
                        pw.Text('TIN: ${receipt.companyTin}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('PAID',
                      style: pw.TextStyle(
                          font: boldFont, fontSize: 14, color: PdfColors.white, letterSpacing: 2)),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 20),
            pw.Text('Payment Receipt',
                style: pw.TextStyle(font: boldFont, fontSize: 22, color: accent)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _kv('Receipt No', receipt.receiptNumber, boldFont),
                    _kv('Invoice No', receipt.invoiceNumber, boldFont),
                    _kv('Received From', receipt.clientName, boldFont),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _kv('Date Paid', Formatters.date(receipt.datePaid), boldFont),
                    _kv('Method', receipt.method.label, boldFont),
                  ],
                ),
              ],
            ),
            if (receipt.monthsPaid != null && receipt.serviceExpiry != null) ...[
              gpsServiceBox(
                monthsPaid: receipt.monthsPaid!,
                expiry: receipt.serviceExpiry!,
                boldFont: boldFont,
                baseFont: baseFont,
                accent: accent,
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('AMOUNT PAID',
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text(Formatters.money(receipt.amountPaid),
                      style: pw.TextStyle(font: boldFont, fontSize: 26, color: accent)),
                ],
              ),
            ),
            if (showAmountInWords) ...[
              pw.SizedBox(height: 10),
              pw.Center(
                child: amountInWordsLine(receipt.amountPaid, boldFont, baseFont),
              ),
            ],
            pw.SizedBox(height: 30),
            pw.Text(
              'This receipt confirms that the above payment has been received in full.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Thank you for your business.',
                style: pw.TextStyle(font: boldFont, fontSize: 10, color: accent)),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ---------------------------------------------------------------------
  // CLASSIC — traditional serif layout, bordered table, formal tone
  // ---------------------------------------------------------------------
  static void _buildClassic(pw.Document doc, Invoice invoice, bool showAmountInWords) {
    final baseFont = pw.Font.times();
    final boldFont = pw.Font.timesBold();
    final border = pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
    );

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    if (_logoImage(invoice.companyLogoBase64) != null) ...[
                      _logoImage(invoice.companyLogoBase64)!,
                      pw.SizedBox(width: 10),
                    ],
                    pw.Text(invoice.companyName,
                        style: pw.TextStyle(font: boldFont, fontSize: 20)),
                  ],
                ),
                pw.Text('INVOICE',
                    style: pw.TextStyle(
                        font: boldFont, fontSize: 24, letterSpacing: 2)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Divider(thickness: 1.2, color: PdfColors.grey700),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('From',
                        style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    pw.Text(invoice.companyName),
                    if (invoice.companyAddress.isNotEmpty)
                      pw.Text(invoice.companyAddress),
                    if (invoice.companyEmail.isNotEmpty)
                      pw.Text(invoice.companyEmail),
                    if (invoice.companyPhone.isNotEmpty)
                      pw.Text(invoice.companyPhone),
                    if (invoice.companyTin.isNotEmpty)
                      pw.Text('TIN: ${invoice.companyTin}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To',
                        style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    pw.Text(invoice.client.name),
                    if (invoice.client.address.isNotEmpty)
                      pw.Text(invoice.client.address),
                    if (invoice.client.email.isNotEmpty)
                      pw.Text(invoice.client.email),
                    if (invoice.client.phone.isNotEmpty)
                      pw.Text(invoice.client.phone),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _kv('Invoice #', invoice.invoiceNumber, boldFont),
                    _kv('Issue Date', Formatters.date(invoice.issueDate), boldFont),
                    _kv('Due Date', Formatters.date(invoice.dueDate), boldFont),
                    _kv('Status', invoice.status.label, boldFont),
                  ],
                ),
              ),
            ],
          ),
          if (invoice.isGpsService && invoice.serviceExpiry != null)
            gpsServiceBox(
              monthsPaid: invoice.monthsPaid,
              expiry: invoice.serviceExpiry!,
              boldFont: boldFont,
              baseFont: baseFont,
              accent: PdfColors.grey800,
            ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Description', font: boldFont, header: true),
                  _cell('Qty', font: boldFont, header: true, align: pw.TextAlign.center),
                  _cell('Unit Price', font: boldFont, header: true, align: pw.TextAlign.right),
                  _cell('Amount', font: boldFont, header: true, align: pw.TextAlign.right),
                ],
              ),
              ...invoice.items.map((item) => pw.TableRow(children: [
                    _cell(item.description),
                    _cell(item.quantity.toStringAsFixed(0),
                        align: pw.TextAlign.center),
                    _cell(Formatters.money(item.unitPrice), align: pw.TextAlign.right),
                    _cell(Formatters.money(item.total), align: pw.TextAlign.right),
                  ])),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(10),
                decoration: border,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', Formatters.money(invoice.subtotal)),
                    if (invoice.discount > 0)
                      _totalRow('Discount (${invoice.discount.toStringAsFixed(1)}%)',
                          '- ${Formatters.money(invoice.discountAmount)}'),
                    if (invoice.taxRate > 0)
                      _totalRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%)',
                          Formatters.money(invoice.taxAmount)),
                    pw.Divider(color: PdfColors.grey700),
                    _totalRow('Total Due', Formatters.money(invoice.total),
                        bold: true, font: boldFont),
                  ],
                ),
              ),
            ],
          ),
          if (showAmountInWords)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                  width: 220, child: amountInWordsLine(invoice.total, boldFont, baseFont)),
            ),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Notes', style: pw.TextStyle(font: boldFont, fontSize: 11)),
            pw.Text(invoice.notes),
          ],
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text('Thank you for your business.',
                style: pw.TextStyle(font: baseFont, fontSize: 10, color: PdfColors.grey700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MODERN — bold color header band, clean sans-serif, accent totals
  // ---------------------------------------------------------------------
  static void _buildModern(pw.Document doc, Invoice invoice, bool showAmountInWords) {
    const accent = PdfColor.fromInt(0xFF2F6FED); // blue accent
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        margin: pw.EdgeInsets.zero,
        header: (context) => pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(36, 30, 36, 24),
          decoration: const pw.BoxDecoration(color: accent),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_logoImage(invoice.companyLogoBase64, size: 40) != null) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: _logoImage(invoice.companyLogoBase64, size: 36),
                    ),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(invoice.companyName,
                          style: pw.TextStyle(
                              font: boldFont, fontSize: 20, color: PdfColors.white)),
                      if (invoice.companyAddress.isNotEmpty)
                        pw.Text(invoice.companyAddress,
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                      if (invoice.companyEmail.isNotEmpty)
                        pw.Text(invoice.companyEmail,
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                      if (invoice.companyTin.isNotEmpty)
                        pw.Text('TIN: ${invoice.companyTin}',
                            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE',
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 26,
                          color: PdfColors.white,
                          letterSpacing: 2)),
                  pw.Text('#${invoice.invoiceNumber}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(36, 24, 36, 36),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILLED TO',
                            style: pw.TextStyle(
                                font: boldFont, fontSize: 9, color: accent)),
                        pw.Text(invoice.client.name,
                            style: pw.TextStyle(font: boldFont, fontSize: 12)),
                        if (invoice.client.address.isNotEmpty)
                          pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.client.email.isNotEmpty)
                          pw.Text(invoice.client.email, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _kv('Issue Date', Formatters.date(invoice.issueDate), boldFont),
                        _kv('Due Date', Formatters.date(invoice.dueDate), boldFont),
                        _kv('Status', invoice.status.label, boldFont),
                      ],
                    ),
                  ],
                ),
                if (invoice.isGpsService && invoice.serviceExpiry != null)
                  gpsServiceBox(
                    monthsPaid: invoice.monthsPaid,
                    expiry: invoice.serviceExpiry!,
                    boldFont: boldFont,
                    baseFont: baseFont,
                    accent: accent,
                  ),
                pw.SizedBox(height: 24),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: accent),
                      children: [
                        _cell('DESCRIPTION', font: boldFont, header: true, color: PdfColors.white),
                        _cell('QTY', font: boldFont, header: true, align: pw.TextAlign.center, color: PdfColors.white),
                        _cell('PRICE', font: boldFont, header: true, align: pw.TextAlign.right, color: PdfColors.white),
                        _cell('TOTAL', font: boldFont, header: true, align: pw.TextAlign.right, color: PdfColors.white),
                      ],
                    ),
                    ...invoice.items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i.isEven ? PdfColors.grey100 : PdfColors.white,
                        ),
                        children: [
                          _cell(item.description),
                          _cell(item.quantity.toStringAsFixed(0), align: pw.TextAlign.center),
                          _cell(Formatters.money(item.unitPrice), align: pw.TextAlign.right),
                          _cell(Formatters.money(item.total), align: pw.TextAlign.right),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 230,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        children: [
                          _totalRow('Subtotal', Formatters.money(invoice.subtotal)),
                          if (invoice.discount > 0)
                            _totalRow('Discount (${invoice.discount.toStringAsFixed(1)}%)',
                                '- ${Formatters.money(invoice.discountAmount)}'),
                          if (invoice.taxRate > 0)
                            _totalRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%)',
                                Formatters.money(invoice.taxAmount)),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: _totalRow('Total Due', Formatters.money(invoice.total),
                                bold: true, font: boldFont, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showAmountInWords)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.SizedBox(
                        width: 230, child: amountInWordsLine(invoice.total, boldFont, baseFont)),
                  ),
                if (invoice.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text('NOTES', style: pw.TextStyle(font: boldFont, fontSize: 9, color: accent)),
                  pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // MINIMAL — lots of whitespace, thin rules, no boxes, understated
  // ---------------------------------------------------------------------
  static void _buildMinimal(pw.Document doc, Invoice invoice, bool showAmountInWords) {
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
   final line = pw.Divider(
  thickness: 0.5,
  color: PdfColors.grey400,
);

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 40),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (_logoImage(invoice.companyLogoBase64, size: 30) != null) ...[
                _logoImage(invoice.companyLogoBase64, size: 30)!,
                pw.SizedBox(width: 8),
              ],
              pw.Text(invoice.companyName.toUpperCase(),
                  style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 1.5)),
            ],
          ),
          if (invoice.companyTin.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text('TIN: ${invoice.companyTin}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice',
                  style: pw.TextStyle(font: baseFont, fontSize: 28, color: PdfColors.grey800)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(invoice.invoiceNumber,
                      style: pw.TextStyle(font: boldFont, fontSize: 11)),
                  pw.Text(Formatters.date(invoice.issueDate),
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          line,
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO',
                        style: pw.TextStyle(
                            font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.client.name, style: pw.TextStyle(font: boldFont, fontSize: 11)),
                    if (invoice.client.address.isNotEmpty)
                      pw.Text(invoice.client.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    if (invoice.client.email.isNotEmpty)
                      pw.Text(invoice.client.email, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DUE DATE',
                        style: pw.TextStyle(
                            font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(Formatters.date(invoice.dueDate), style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('STATUS',
                        style: pw.TextStyle(
                            font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.status.label, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          if (invoice.isGpsService && invoice.serviceExpiry != null)
            gpsServiceBox(
              monthsPaid: invoice.monthsPaid,
              expiry: invoice.serviceExpiry!,
              boldFont: boldFont,
              baseFont: baseFont,
              accent: PdfColors.grey800,
            ),
          pw.SizedBox(height: 26),
          pw.Row(
            children: [
              pw.Expanded(flex: 4, child: pw.Text('DESCRIPTION',
                  style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1))),
              pw.Expanded(flex: 1, child: pw.Text('QTY',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1))),
              pw.Expanded(flex: 2, child: pw.Text('PRICE',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1))),
              pw.Expanded(flex: 2, child: pw.Text('AMOUNT',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1))),
            ],
          ),
          pw.SizedBox(height: 8),
          line,
          ...invoice.items.map((item) => pw.Column(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 4, child: pw.Text(item.description, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(flex: 1, child: pw.Text(item.quantity.toStringAsFixed(0),
                            textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(flex: 2, child: pw.Text(Formatters.money(item.unitPrice),
                            textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                        pw.Expanded(flex: 2, child: pw.Text(Formatters.money(item.total),
                            textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 0.3, color: PdfColors.grey300),
                ],
              )),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 200,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', Formatters.money(invoice.subtotal), light: true),
                    if (invoice.discount > 0)
                      _totalRow('Discount', '- ${Formatters.money(invoice.discountAmount)}', light: true),
                    if (invoice.taxRate > 0)
                      _totalRow('Tax', Formatters.money(invoice.taxAmount), light: true),
                    pw.SizedBox(height: 6),
                    line,
                    pw.SizedBox(height: 6),
                    _totalRow('Total', Formatters.money(invoice.total), bold: true, font: boldFont),
                  ],
                ),
              ),
            ],
          ),
          if (showAmountInWords)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                  width: 200, child: amountInWordsLine(invoice.total, boldFont, baseFont)),
            ),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 28),
            pw.Text('NOTES',
                style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey500, letterSpacing: 1)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Logo + GPS Service Charge helpers (shared across templates)
  // ---------------------------------------------------------------------
  static pw.Widget amountInWordsLine(double amount, pw.Font boldFont, pw.Font baseFont) {
    final words = amountInWords(amount, currencySymbol: Formatters.currencySymbol);
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
              text: 'Amount in words: ',
              style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey700)),
          pw.TextSpan(
              text: words,
              style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey800)),
        ]),
      ),
    );
  }

  static Uint8List? _decodeLogo(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  static pw.Widget? _logoImage(String? base64String, {double size = 46}) {
    final bytes = _decodeLogo(base64String);
    if (bytes == null) return null;
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
    );
  }

  /// A highlighted box shown on GPS Service Charge invoices/receipts,
  /// stating how many months were paid for and the exact expiry date.
  static pw.Widget gpsServiceBox({
    required int monthsPaid,
    required DateTime expiry,
    required pw.Font boldFont,
    required pw.Font baseFont,
    PdfColor accent = const PdfColor.fromInt(0xFF2F6FED),
  }) {
    final expired = expiry.isBefore(DateTime.now());
    final statusColor = expired ? PdfColors.red : PdfColors.green800;
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 14, bottom: 4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: accent, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GPS SERVICE CHARGE',
                  style: pw.TextStyle(font: boldFont, fontSize: 10, color: accent)),
              pw.Text(
                'Paid for $monthsPaid month${monthsPaid == 1 ? '' : 's'}',
                style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey800),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('EXPIRES ON',
                  style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.grey600)),
              pw.Text(Formatters.date(expiry),
                  style: pw.TextStyle(font: boldFont, fontSize: 11, color: statusColor)),
              if (expired)
                pw.Text('EXPIRED',
                    style: pw.TextStyle(font: boldFont, fontSize: 8, color: PdfColors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared small helpers
  // ---------------------------------------------------------------------
  static pw.Widget _kv(String label, String value, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: boldFont, fontSize: 9)),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9)),
        ]),
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.Font? font,
    bool header = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: header ? 9 : 10,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    bool light = false,
    pw.Font? font,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 12 : 10,
                  color: light ? PdfColors.grey600 : PdfColors.black,
                  font: bold ? font : null)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 12 : 10,
                  font: bold ? font : null,
                  color: bold ? color : (light ? PdfColors.grey600 : PdfColors.black))),
        ],
      ),
    );
  }
}
