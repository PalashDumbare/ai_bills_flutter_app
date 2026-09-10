import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _selectedFile;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null) return;

    await ref.read(uploadProvider.notifier).uploadAndProcess(_selectedFile!);

    if (!mounted) return;

    final state = ref.read(uploadProvider);
    if (state.status == UploadStatus.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document processed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (state.status == UploadStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Upload failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _selectedFile != null
                  ? _buildPreview(uploadState)
                  : _buildSourceSelector(),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: uploadState.status == UploadStatus.uploading
                          ? null
                          : () {
                              setState(() {
                                _selectedFile = null;
                              });
                              ref.read(uploadProvider.notifier).reset();
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: uploadState.status == UploadStatus.uploading ||
                              uploadState.status == UploadStatus.extracting ||
                              uploadState.status == UploadStatus.structuring ||
                              uploadState.status == UploadStatus.indexing
                          ? null
                          : _uploadAndProcess,
                      icon: uploadState.status == UploadStatus.uploading ||
                              uploadState.status == UploadStatus.extracting ||
                              uploadState.status == UploadStatus.structuring ||
                              uploadState.status == UploadStatus.indexing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high),
                      label: Text(_getButtonText(uploadState.status)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getButtonText(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploading:
        return 'Uploading...';
      case UploadStatus.extracting:
        return 'Extracting text...';
      case UploadStatus.structuring:
        return 'Processing data...';
      case UploadStatus.indexing:
        return 'Indexing...';
      default:
        return 'Upload & Process';
    }
  }

  Widget _buildSourceSelector() {
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo or select from gallery',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(UploadState uploadState) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _selectedFile!,
            fit: BoxFit.contain,
          ),
          if (uploadState.status != UploadStatus.idle &&
              uploadState.status != UploadStatus.done &&
              uploadState.status != UploadStatus.error)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: uploadState.status == UploadStatus.uploading
                            ? uploadState.progress
                            : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getButtonText(uploadState.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (uploadState.status == UploadStatus.uploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${(uploadState.progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (uploadState.status == UploadStatus.done)
            Positioned.fill(
              child: Container(
                color: AppColors.success.withValues(alpha: 0.9),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Done!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
