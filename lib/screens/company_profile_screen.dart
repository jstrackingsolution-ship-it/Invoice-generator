import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/company_profile.dart';
import '../providers/company_profile_provider.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String? _logoBase64;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProfileProvider>();

    if (!_initialized && !provider.isLoading) {
      final profile = provider.profile;
      _nameCtrl = TextEditingController(text: profile.name);
      _addressCtrl = TextEditingController(text: profile.address);
      _emailCtrl = TextEditingController(text: profile.email);
      _phoneCtrl = TextEditingController(text: profile.phone);
      _logoBase64 = profile.logoBase64;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: provider.isLoading || !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(child: _logoPicker()),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Company Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Address', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Phone', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This logo and info will be used as the default for new invoices and receipts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _logoPicker() {
    Uint8List? bytes;
    if (_logoBase64 != null && _logoBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(_logoBase64!);
      } catch (_) {
        bytes = null;
      }
    }

    return GestureDetector(
      onTap: _pickLogo,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Icon(Icons.business, size: 48, color: Colors.grey[500]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                final file = await picker.pickImage(
                    source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
                if (ctx.mounted) Navigator.pop(ctx, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () async {
                final file = await picker.pickImage(
                    source: ImageSource.camera, maxWidth: 512, imageQuality: 85);
                if (ctx.mounted) Navigator.pop(ctx, file);
              },
            ),
            if (_logoBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove logo'),
                onTap: () => Navigator.pop(ctx, null),
              ),
          ],
        ),
      ),
    );

    if (picked == null) {
      setState(() => _logoBase64 = null);
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() => _logoBase64 = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = CompanyProfile(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      logoBase64: _logoBase64,
    );
    await context.read<CompanyProfileProvider>().save(profile);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Company profile saved')));
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameCtrl.dispose();
      _addressCtrl.dispose();
      _emailCtrl.dispose();
      _phoneCtrl.dispose();
    }
    super.dispose();
  }
}
