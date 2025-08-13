import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:msbridge/widgets/snakbar.dart';

class ChatAssistantPage extends StatefulWidget {
  const ChatAssistantPage({super.key});

  @override
  State<ChatAssistantPage> createState() => _ChatAssistantPageState();
}

class _ChatAssistantPageState extends State<ChatAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  bool _includePersonal = true;
  bool _includeMsNotes = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => NotesChatProvider(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: const CustomAppBar(title: 'Ask AI', showBackButton: true),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _buildConsentCard(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Personal'),
                    selected: _includePersonal,
                    onSelected: (v) => setState(() => _includePersonal = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('MS Notes'),
                    selected: _includeMsNotes,
                    onSelected: (v) => setState(() => _includeMsNotes = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<NotesChatProvider>(
                builder: (context, chat, _) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final m = chat.messages[index];
                      final align = m.fromUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start;
                      final bubbleColor = m.fromUser
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.surface;
                      final textColor = m.fromUser
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary;
                      return Column(
                        crossAxisAlignment: align,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.3)),
                            ),
                            child: SelectableText(m.text,
                                style: TextStyle(color: textColor)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildComposer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCard(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AiConsentProvider>(
      builder: (context, consent, _) {
        return Card(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.secondary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(LineIcons.userShield, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Allow AI to use your notes for answers? You can turn this off anytime.',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                Switch(
                  value: consent.enabled,
                  onChanged: (v) async {
                    await consent.setEnabled(v);
                    if (!v) {
                      CustomSnackBar.show(
                          context, 'AI access to notes disabled');
                    }
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer2<NotesChatProvider, AiConsentProvider>(
              builder: (context, chat, consent, _) {
                return IconButton(
                  icon: Icon(LineIcons.paperPlane,
                      color: theme.colorScheme.secondary),
                  onPressed: () async {
                    final q = _controller.text.trim();
                    if (q.isEmpty) return;
                    if (!consent.enabled && _includePersonal) {
                      CustomSnackBar.show(
                          context, 'Enable AI access to use personal notes');
                      return;
                    }
                    try {
                      await chat.startSession(
                          includePersonal: consent.enabled && _includePersonal,
                          includeMsNotes: _includeMsNotes);
                      await chat.ask(q);
                      _controller.clear();
                    } catch (e) {
                      CustomSnackBar.show(context, 'Error: $e');
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
