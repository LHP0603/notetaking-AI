import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class SummaryTab extends StatefulWidget {
  final int? noteId;
  final String? summaryHtml;
  final bool hasSummary;
  final bool enabled;
  final bool isSummarizing;
  final VoidCallback onChanged;
  final VoidCallback? onSaved;
  final Future<String?> Function() onStartSummarization;
  final Future<String?> Function(String summary)? onSaveSummary;

  const SummaryTab({
    super.key,
    this.noteId,
    required this.summaryHtml,
    required this.hasSummary,
    required this.enabled,
    required this.isSummarizing,
    required this.onChanged,
    required this.onStartSummarization,
    this.onSaved,
    this.onSaveSummary,
  });

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab> {
  late quill.QuillController _controller;
  late String _initialContent;

  @override
  void initState() {
    super.initState();
    _initializeController(widget.summaryHtml ?? '');
  }

  @override
  void didUpdateWidget(SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSummary = widget.summaryHtml ?? '';
    if (oldWidget.summaryHtml == newSummary) {
      return;
    }
    if (_getDocumentContent() != _initialContent) {
      return;
    }
    _resetController(newSummary);
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    super.dispose();
  }

  void _initializeController(String summaryText) {
    _controller = _buildController(summaryText);
    _initialContent = _getDocumentContent();
    _controller.addListener(_onContentChanged);
  }

  void _resetController(String summaryText) {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _controller = _buildController(summaryText);
    _initialContent = _getDocumentContent();
    _controller.addListener(_onContentChanged);
  }

  quill.QuillController _buildController(String summaryText) {
    if (summaryText.trim().isEmpty) {
      return quill.QuillController.basic();
    }
    
    try {
      // Try to parse as JSON delta first
      dynamic jsonData = jsonDecode(summaryText);

      // Handle double-encoded JSON (string within string)
      if (jsonData is String) {
        jsonData = jsonDecode(jsonData);
      }
      
      final doc = quill.Document.fromJson(jsonData);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      print('Error parsing summary JSON: $e');
      print('Summary text: $summaryText');
      // If parsing fails, treat as plain text
      final doc = quill.Document()..insert(0, summaryText);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  String _getDocumentContent() {
    return _controller.document.toPlainText().trim();
  }

  String _getDocumentJson() {
    return jsonEncode(_controller.document.toDelta().toJson());
  }

  void _onContentChanged() {
    if (_getDocumentContent() != _initialContent) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (widget.isSummarizing) {
      return _buildSummarizingView();
    }

    if (!widget.enabled) {
      return _buildDisabledView();
    }

    if (!widget.hasSummary) {
      return _buildNoSummaryView();
    }

    return Column(
      children: [
        if (!isKeyboardVisible)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: quill.QuillToolbar.simple(
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(),
              ),
            ),
          ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF101822),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _controller,
                  sharedConfigurations: const quill.QuillSharedConfigurations(),
                  placeholder: 'Summary content...',
                ),
              ),
            ),
          ),
        ),
        if (!isKeyboardVisible)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101822),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Summary'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.grey[500]),
            const SizedBox(height: 24),
            const Text(
              'Summary Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please transcribe the audio first before generating a summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSummaryView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.summarize, size: 80, color: Colors.grey[500]),
            const SizedBox(height: 24),
            const Text(
              'No Summary Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This audio has not been summarized yet. Click the button below to generate a summary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _handleGenerateSummary,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarizingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Generating Summary...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Please wait while we generate a summary.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateSummary() async {
    final errorMessage = await widget.onStartSummarization();
    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summarization started. Please wait...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start summary: $errorMessage')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (widget.onSaveSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save function not available')),
      );
      return;
    }

    final summaryJson = _getDocumentJson();
    final errorMessage = await widget.onSaveSummary!(summaryJson);

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      _initialContent = _getDocumentContent();
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary saved successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save summary: $errorMessage')),
      );
    }
  }
}
