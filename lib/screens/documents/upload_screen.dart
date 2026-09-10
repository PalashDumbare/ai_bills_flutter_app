import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/upload_provider.dart';

enum PickedFileType { image, pdf }

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _selectedFile;
  Uint8List? _fileBytes;
  PickedFileType? _fileType;
  String? _fileName;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedFile = File(image.path);
        _fileBytes = bytes;
        _fileType = PickedFileType.image;
        _fileName = image.name;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result.isNotEmpty) {
      final file = result.first;
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedFile = File(file.path ?? '');
        _fileBytes = bytes;
        _fileType = PickedFileType.pdf;
        _fileName = file.name;
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
                                _fileBytes = null;
                                _fileType = null;
                                _fileName = null;
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Pick PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
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
              Icons.file_upload_outlined,
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
              'Take a photo, select from gallery, or pick a PDF',
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
          if (_fileType == PickedFileType.pdf)
            _buildPdfPreview()
          else if (_fileBytes != null)
            Image.memory(
              _fileBytes!,
              fit: BoxFit.contain,
            )
          else if (!kIsWeb && _selectedFile != null)
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

  Widget _buildPdfPreview() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _fileName ?? 'PDF Document',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'PDF file ready for processing',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
