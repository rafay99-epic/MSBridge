import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/file_convters/markdown/markdown_convter.dart';
import 'package:msbridge/core/file_convters/pdf/pdfconvter.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/repo/note_taking_actions_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key, this.note});

  final NoteTakingModel? note;

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote>
    with SingleTickerProviderStateMixin {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  String? _aiSummary;
  bool isGeneratingSummary = false;
  final InternetHelper _internetHelper = InternetHelper();

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!.noteTitle;
      _loadQuillContent(widget.note!.noteContent);
    } else {
      _controller = QuillController.basic();
    }
  }

  Future<void> _loadQuillContent(String noteContent) async {
    try {
      final jsonResult = jsonDecode(noteContent);
      if (jsonResult is List) {
        _controller = QuillController(
          document: Document.fromJson(jsonResult),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _controller = QuillController(
            document: Document()..insert(0, noteContent),
            selection: const TextSelection.collapsed(offset: 0));
      }
    } catch (e) {
      _controller = QuillController(
          document: Document()..insert(0, noteContent),
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _internetHelper.dispose();

    super.dispose();
  }

  void saveNote() async {
    String title = _titleController.text.trim();
    String content;

    try {
      content = jsonEncode(_controller.document.toDelta().toJson());
    } catch (e) {
      content = _controller.document.toPlainText().trim();
    }
    SaveNoteResult result;

    try {
      if (widget.note != null) {
        result = await NoteTakingActions.updateNote(
          note: widget.note!,
          title: title,
          content: content,
          isSynced: false,
        );
        if (result.success) {
          CustomSnackBar.show(context, result.message);
          Navigator.pop(context);
        }
      } else {
        result = await NoteTakingActions.saveNote(
          title: title,
          content: content,
        );

        if (result.success) {
          CustomSnackBar.show(context, result.message);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      CustomSnackBar.show(context, "Error saving note: $e");
    }
  }

  void _showAiSummaryBottomSheet(BuildContext context, String? aiSummary) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) {
        return Material(
          child: SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.85,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 16),
                    Expanded(child: _buildSummaryText(context, aiSummary)),
                    const SizedBox(height: 16),
                    _buildButtonRow(context, aiSummary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'AI Note Summary',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildSummaryText(BuildContext context, String? aiSummary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: aiSummary ?? 'No summary generated yet.',
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context, String? aiSummary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: aiSummary == null
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: aiSummary));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Summary copied!'),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          icon: const Icon(Icons.copy, size: 20),
          label: const Text(
            'Copy Summary',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20),
          label: const Text(
            'Close',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAiSummary(BuildContext context) async {
    if (_internetHelper.connectivitySubject.value == false) {
      CustomSnackBar.show(context, "Sorry No Internet Connection!");

      return;
    }
    setState(() {
      isGeneratingSummary = true;
      _aiSummary = null;
    });

    final noteContent = _controller.document.toPlainText().trim();
    final noteSummaryProvider =
        Provider.of<NoteSumaryProvider>(context, listen: false);

    try {
      await noteSummaryProvider.summarizeNote(noteContent);

      final aiResponse = noteSummaryProvider.messages.lastWhere(
        (message) => message["role"] == "ai",
        orElse: () => {"role": "", "content": "No summary available."},
      )["content"];

      setState(() {
        _aiSummary = aiResponse;
      });
    } catch (e) {
      setState(() {
        _aiSummary = "Error generating summary: $e";
      });
    } finally {
      setState(() {
        isGeneratingSummary = false;
      });

      _showAiSummaryBottomSheet(context, _aiSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        backbutton: true,
        actions: [
          IconButton(
            icon: const Icon(LineIcons.robot),
            onPressed: () {
              _generateAiSummary(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Material(
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: const Text('Export to PDF'),
                          onTap: () => {
                            PdfExporter.exportToPdf(context,
                                _titleController.text.trim(), _controller),
                            Navigator.pop(context),
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.text_snippet),
                          title: const Text('Export to Markdown'),
                          onTap: () {
                            Navigator.pop(context);

                            MarkdownExporter.exportToMarkdown(context,
                                _titleController.text.trim(), _controller);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                  placeholder: 'Note...',
                  expands: true,
                  customStyles: DefaultStyles(
                    paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const VerticalSpacing(5, 0),
                        const VerticalSpacing(0, 0),
                        null),
                  ),
                ),
              ),
            ),
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                multiRowsDisplay: false,
                toolbarSize: 50,
                showCodeBlock: true,
                showQuote: true,
                showLink: true,
                showFontSize: true,
                showFontFamily: true,
                showIndent: true,
                headerStyleType: HeaderStyleType.buttons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
