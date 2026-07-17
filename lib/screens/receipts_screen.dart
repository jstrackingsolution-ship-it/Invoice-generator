import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receipt_provider.dart';
import '../utils/formatters.dart';
import 'receipt_preview_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.receipts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text('No receipts yet'),
                        const SizedBox(height: 4),
                        Text(
                          'Receipts appear here once you mark an invoice as paid.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = provider.receipts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x1A1B8A5A),
                          child: Icon(Icons.check_circle, color: Color(0xFF1B8A5A)),
                        ),
                        title: Text(receipt.receiptNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${receipt.clientName} • Invoice ${receipt.invoiceNumber}\n'
                          '${Formatters.date(receipt.datePaid)} • ${receipt.method.name}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          Formatters.money(receipt.amountPaid),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ReceiptPreviewScreen(receipt: receipt)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
