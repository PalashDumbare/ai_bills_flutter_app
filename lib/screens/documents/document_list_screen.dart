import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/document.dart';
import '../../providers/documents_provider.dart';

class DocumentListScreen extends ConsumerWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(documentsProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            onPressed: () async {
              await context.push('/upload');
              ref.read(documentsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (docs) => docs.isEmpty ? _buildEmptyState(context) : _buildList(context, ref, docs),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Document> docs) {
    return RefreshIndicator(
      onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DocumentCard(doc: docs[i]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 72, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            const Text('No documents found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Upload bills and invoices to see them here', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add),
              label: const Text('Upload Document'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.read(documentsProvider.notifier).refresh(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final isAppliance = doc.documentType == 'appliance_invoice';
    final isBill = doc.documentType == 'bill';
    final isUnprocessed = doc.documentType == null;

    Color accent;
    IconData icon;
    String label;
    if (isAppliance) {
      accent = AppColors.secondary;
      icon = Icons.handyman_outlined;
      label = 'Appliance';
    } else if (isBill) {
      accent = AppColors.primary;
      icon = Icons.receipt_long_outlined;
      label = 'Bill';
    } else {
      accent = AppColors.textSecondary;
      icon = Icons.description_outlined;
      label = 'Processing';
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/document/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDate(doc.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (isUnprocessed) ...[
                      const SizedBox(height: 6),
                      const Text('Tap to view details', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
