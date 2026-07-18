import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/ai_settings_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/receipt_provider.dart';
import '../services/ai_accountant_service.dart';
import '../utils/finance_insights.dart';
import 'ai_settings_screen.dart';

const List<String> _suggestedQuestions = [
  'How much did I collect this month?',
  'Which clients owe me the most?',
  'Any GPS services expiring soon?',
  'Summarize my finances this month',
];

class AiAccountantScreen extends StatefulWidget {
  const AiAccountantScreen({super.key});

  @override
  State<AiAccountantScreen> createState() => _AiAccountantScreenState();
}

class _AiAccountantScreenState extends State<AiAccountantScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String question) async {
    final apiKey = context.read<AiSettingsProvider>().apiKey;
    if (apiKey.trim().isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
      );
      return;
    }
    if (question.trim().isEmpty || _sending) return;

    final invoices = context.read<InvoiceProvider>();
    final receipts = context.read<ReceiptProvider>();
    final contextSummary = FinanceInsights.buildContextSummary(invoices, receipts);

    final priorTurns = _messages
        .where((m) => !m.isError)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: question.trim()));
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final answer = await AiAccountantService.ask(
        apiKey: apiKey,
        question: question.trim(),
        contextSummary: contextSummary,
        priorTurns: priorTurns.length > 10
            ? priorTurns.sublist(priorTurns.length - 10)
            : priorTurns,
      );
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: answer));
      });
    } on AiAccountantException catch (e) {
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: e.message, isError: true));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            isUser: false, text: 'Something went wrong. Please try again.', isError: true));
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>();
    final aiSettings = context.watch<AiSettingsProvider>();
    final insights = invoices.isLoading ? <Insight>[] : FinanceInsights.quickInsights(invoices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Accountant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'AI Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (insights.isNotEmpty) _InsightsStrip(insights: insights),
          if (!aiSettings.hasApiKey) const _NoKeyBanner(),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChatState(onTapSuggestion: _send)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          _InputBar(controller: _inputCtrl, sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}

class _InsightsStrip extends StatelessWidget {
  final List<Insight> insights;

  const _InsightsStrip({required this.insights});

  Color _colorFor(InsightLevel level) {
    switch (level) {
      case InsightLevel.warning:
        return Colors.orange;
      case InsightLevel.good:
        return Colors.green;
      case InsightLevel.info:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: insights.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final insight = insights[index];
          final color = _colorFor(insight.level);
          return Container(
            width: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: color)),
                const SizedBox(height: 4),
                Text(insight.detail,
                    style: const TextStyle(fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NoKeyBanner extends StatelessWidget {
  const _NoKeyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add your Anthropic API key to chat with the AI Accountant.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
            ),
            child: const Text('Set up'),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final void Function(String) onTapSuggestion;

  const _EmptyChatState({required this.onTapSuggestion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Ask your AI Accountant anything',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'It reasons over your real invoices, receipts, and GPS service data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestedQuestions
                  .map((q) => ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        onPressed: () => onTapSuggestion(q),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = message.isError
        ? Colors.red.shade50
        : isUser
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade200;
    final fg = message.isError
        ? Colors.red.shade900
        : isUser
            ? Colors.white
            : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message.text, style: TextStyle(color: fg, fontSize: 13.5)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final void Function(String) onSend;

  const _InputBar({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: sending ? null : onSend,
                decoration: InputDecoration(
                  hintText: 'Ask about your invoices, revenue, GPS status…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : () => onSend(controller.text),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
