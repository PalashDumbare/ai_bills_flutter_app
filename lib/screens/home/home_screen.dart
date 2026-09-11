import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/documents_provider.dart';
import '../../models/document.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bills'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              docsAsync.when(
                loading: () => _buildStatsRow(0, 0),
                error: (_, __) => _buildStatsRow(0, 0),
                data: (docs) => _buildStatsRow(docs.length, docs.where((d) => d.documentType != null).length),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  TextButton(onPressed: () => context.go('/documents'), child: const Text('View all')),
                ],
              ),
              const SizedBox(height: 8),
              docsAsync.when(
                loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _buildError(ref, e.toString()),
                data: (docs) => docs.isEmpty ? _buildEmptyState(context) : _buildRecentList(context, docs.take(5).toList()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/upload');
          ref.read(documentsProvider.notifier).refresh();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Bill'),
      ),
    );
  }

  Widget _buildStatsRow(int total, int tracked) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.description_outlined, label: 'Documents', value: '$total', color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.verified_outlined, label: 'Processed', value: '$tracked', color: AppColors.secondary)),
      ],
    );
  }

  Widget _buildRecentList(BuildContext context, List<Document> docs) {
    return Column(
      children: docs.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (d.documentType == 'appliance_invoice' ? AppColors.secondary : d.documentType == 'bill' ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(d.documentType == 'appliance_invoice' ? Icons.handyman_outlined : d.documentType == 'bill' ? Icons.receipt_long_outlined : Icons.description_outlined,
                color: d.documentType == 'appliance_invoice' ? AppColors.secondary : d.documentType == 'bill' ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            title: Text(d.filename, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${d.documentType ?? 'processing'} • ${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
            onTap: () => context.push('/document/${d.id}'),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No documents yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Scan your first bill to get started', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: () => context.push('/upload'), icon: const Icon(Icons.camera_alt), label: const Text('Scan Bill')),
          ],
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref, String msg) => Center(
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(height: 8),
        Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        TextButton(onPressed: () => ref.read(documentsProvider.notifier).refresh(), child: const Text('Retry')),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
