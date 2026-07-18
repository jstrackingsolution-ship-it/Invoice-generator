import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ai_settings_provider.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late TextEditingController _keyCtrl;
  bool _obscure = true;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiSettingsProvider>();

    if (!_initialized && !provider.isLoading) {
      _keyCtrl = TextEditingController(text: provider.apiKey);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
      body: provider.isLoading || !_initialized
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('AI Accountant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The AI Accountant answers questions about your invoices, '
                  'receipts, and GPS service status using Anthropic\'s Claude. '
                  'It needs your own Anthropic API key to work.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _keyCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Anthropic API Key',
                    hintText: 'sk-ant-...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stored only on this device (never sent anywhere except '
                  'directly to Anthropic when you ask a question).',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AiSettingsProvider>().saveApiKey(_keyCtrl.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('API key saved')));
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    _keyCtrl.clear();
                    await context.read<AiSettingsProvider>().saveApiKey('');
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('API key removed')));
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Key'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Text(
                    'Don\'t have a key? Create one at console.anthropic.com → '
                    'Settings → API Keys. Standard Anthropic API usage rates '
                    'apply to your account for each question you ask.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    if (_initialized) _keyCtrl.dispose();
    super.dispose();
  }
}
