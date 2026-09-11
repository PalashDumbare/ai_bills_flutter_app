import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/appliance.dart';
import '../../models/bill.dart';
import '../../providers/documents_provider.dart';

class DocumentDetailScreen extends ConsumerWidget {
  final String documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => ref.invalidate(documentDetailProvider(documentId)), child: const Text('Retry')),
              ],
            ),
          ),
        ),
        data: (data) => _buildBody(context, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> data) {
    final docType = data['document_type'] as String?;
    final structured = data['structured_data'] as Map<String, dynamic>?;
    final filename = data['filename'] as String? ?? '-';
    final createdAt = data['created_at'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.description, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(filename, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('ID: $documentId', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(createdAt.isNotEmpty ? createdAt.substring(0, 10) : '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _typeBadge(docType),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (structured == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.hourglass_empty, size: 48, color: AppColors.warning.withValues(alpha: 0.8)),
                    const SizedBox(height: 12),
                    Text(docType == null ? 'Not yet processed' : 'No structured data', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text('Upload → Extract → Structure → Index to generate details', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else if (docType == 'appliance_invoice')
            _ApplianceCard(data: Appliance.fromJson(structured))
          else if (docType == 'bill')
            _BillCard(data: Bill.fromJson(structured))
          else
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(structured.toString()))),
        ],
      ),
    );
  }

  Widget _typeBadge(String? t) {
    Color c;
    String l;
    if (t == 'appliance_invoice') { c = AppColors.secondary; l = 'Appliance'; }
    else if (t == 'bill') { c = AppColors.primary; l = 'Bill'; }
    else { c = AppColors.textSecondary; l = 'Pending'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(l, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

class _ApplianceCard extends StatelessWidget {
  final Appliance data;
  const _ApplianceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final expiry = data.warrantyExpiry;
    final isExpiringSoon = expiry != null && expiry.difference(DateTime.now()).inDays < 90 && expiry.isAfter(DateTime.now());
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: AppColors.secondary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.handyman, color: AppColors.secondary, size: 28),
                const SizedBox(height: 8),
                Text(data.product ?? 'Appliance', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text([data.brand, data.model].where((e) => e != null && e.isNotEmpty).join(' • '), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _fieldsCard([
          _field('Brand', data.brand ?? '-'),
          _field('Product', data.product ?? '-'),
          _field('Model', data.model ?? '-'),
          _field('Purchase Date', data.purchaseDate != null ? '${data.purchaseDate!.day}/${data.purchaseDate!.month}/${data.purchaseDate!.year}' : '-'),
          _field('Amount', data.amount != null ? '₹${data.amount!.toStringAsFixed(2)}' : '-'),
          _field('Warranty', data.warrantyMonths != null ? '${data.warrantyMonths} months' : '-'),
          _field('Warranty Expiry', data.warrantyExpiry != null ? '${data.warrantyExpiry!.day}/${data.warrantyExpiry!.month}/${data.warrantyExpiry!.year}' : '-',
            highlight: isExpired ? AppColors.error : isExpiringSoon ? AppColors.warning : null),
        ]),
        if (isExpired || isExpiringSoon) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isExpired ? AppColors.error : AppColors.warning).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(isExpired ? Icons.error : Icons.warning_amber, color: isExpired ? AppColors.error : AppColors.warning),
                const SizedBox(width: 10),
                Expanded(child: Text(isExpired ? 'Warranty expired' : 'Warranty expires soon (<3 months)', style: TextStyle(fontWeight: FontWeight.w600, color: isExpired ? AppColors.error : AppColors.warning))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill data;
  const _BillCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: AppColors.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(data.provider ?? 'Bill', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text(data.billType ?? '-', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _fieldsCard([
          _field('Provider', data.provider ?? '-'),
          _field('Bill Type', data.billType ?? '-'),
          _field('Amount', data.amount != null ? '₹${data.amount!.toStringAsFixed(2)}' : '-'),
          _field('Due Date', data.dueDate != null ? '${data.dueDate!.day}/${data.dueDate!.month}/${data.dueDate!.year}' : '-'),
          _field('Billing Period', data.billingPeriod ?? '-'),
        ]),
      ],
    );
  }
}

Widget _fieldsCard(List<Widget> fields) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: fields)));

Widget _field(String label, String value, {Color? highlight}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: highlight ?? AppColors.textPrimary))),
        ],
      ),
    );
