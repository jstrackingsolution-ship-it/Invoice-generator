import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../providers/invoice_provider.dart';
import '../utils/formatters.dart';
import '../utils/month_utils.dart';
import 'company_profile_screen.dart';
import 'invoice_form_screen.dart';
import 'invoice_preview_screen.dart';
import 'receipts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.unpaid:
        return Colors.orange;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.draft:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SJ TRACKING SOLUTION'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Receipts',
            icon: const Icon(Icons.receipt),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceiptsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Company Profile',
            icon: const Icon(Icons.business),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummary(context, provider)),
                  SliverToBoxAdapter(child: _buildMonthlySummary(context, provider)),
                  if (provider.invoices.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final invoice = provider.invoices[index];
                            return _InvoiceCard(
                              invoice: invoice,
                              statusColor: _statusColor(invoice.status),
                            );
                          },
                          childCount: provider.invoices.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, InvoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              label: 'Total Invoices',
              value: '${provider.invoiceCount}',
              icon: Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              label: 'Revenue',
              value: Formatters.money(provider.totalRevenue),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryTile(
              label: 'Outstanding',
              value: Formatters.money(provider.totalOutstanding),
              icon: Icons.hourglass_bottom,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(BuildContext context, InvoiceProvider provider) {
    final stats = provider.monthlyStats(_selectedMonth);
    final months = recentMonths(12);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Overview', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<DateTime>(
                value: _selectedMonth,
                underline: const SizedBox.shrink(),
                items: months
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(monthYearFormat.format(m)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedMonth = v);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MonthStat(
                  label: 'Invoiced',
                  value: Formatters.money(stats.totalInvoiced),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _MonthStat(
                  label: 'Amount Paid',
                  value: Formatters.money(stats.totalPaid),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _MonthStat(
                  label: 'Remaining',
                  value: Formatters.money(stats.totalRemaining),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MonthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final Color statusColor;

  const _InvoiceCard({required this.invoice, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.description, color: statusColor, size: 20),
        ),
        title: Text(invoice.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              invoice.client.name.isEmpty ? 'No client name' : invoice.client.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (invoice.isGpsService && invoice.serviceExpiry != null)
              Text(
                '${invoice.isServiceExpired ? 'Expired' : 'Expires'} '
                '${Formatters.date(invoice.serviceExpiry!)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: invoice.isServiceExpired ? Colors.red : Colors.blueGrey,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.money(invoice.total),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                invoice.status.label,
                style: TextStyle(
                    color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: invoice)),
        ),
        onLongPress: () => _showActions(context),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => InvoiceFormScreen(existingInvoice: invoice)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Invoice'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<InvoiceProvider>().deleteInvoice(invoice.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No invoices yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tap "New Invoice" to create your first invoice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
