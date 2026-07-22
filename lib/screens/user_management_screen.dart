import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/auth_provider.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = auth.pendingUsers;
    final active = auth.users.where((u) => u.isAdmin || u.isApproved).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: auth.users.isEmpty
          ? const Center(child: Text('No users yet'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (pending.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.hourglass_top, size: 18, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text('Pending Approval (${pending.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _UserTile(user: u),
                      )),
                  const SizedBox(height: 20),
                ],
                const Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...active.map((u) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _UserTile(user: u),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const _CreateUserDialog(),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Create User'),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final pending = !user.isAdmin && !user.isApproved;

    return Card(
      color: pending ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              user.isAdmin ? Colors.deepPurple.shade100 : Colors.blueGrey.shade100,
          child: Icon(user.isAdmin ? Icons.shield : Icons.person,
              color: user.isAdmin ? Colors.deepPurple : Colors.blueGrey),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
            if (pending) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Pending',
                    style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          user.isAdmin
              ? 'Administrator — full access'
              : pending
                  ? 'Waiting for approval to sign in'
                  : user.permissions.isEmpty
                      ? 'Approved — no permissions granted yet'
                      : user.permissions.map((p) => p.label).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: user.isAdmin
            ? null
            : pending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => context.read<AuthProvider>().setApproved(user.id, true),
                      ),
                      IconButton(
                        tooltip: 'Reject (delete)',
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _confirmDelete(context, user),
                      ),
                    ],
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showDialog(
                          context: context,
                          builder: (_) => _EditPermissionsDialog(user: user),
                        );
                      } else if (value == 'revoke') {
                        context.read<AuthProvider>().setApproved(user.id, false);
                      } else if (value == 'delete') {
                        _confirmDelete(context, user);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit permissions')),
                      PopupMenuItem(value: 'revoke', child: Text('Revoke approval')),
                      PopupMenuItem(value: 'delete', child: Text('Delete user')),
                    ],
                  ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Remove "${user.username}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().deleteUser(user.id);
    }
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final Set<Permission> _selected = {};
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().createUser(
          username: _usernameCtrl.text,
          password: _passwordCtrl.text,
          permissions: _selected,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) => (v == null || v.length < 4) ? 'At least 4 characters' : null,
              ),
              const SizedBox(height: 16),
              const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
              ...Permission.values.map((p) => CheckboxListTile(
                    value: _selected.contains(p),
                    title: Text(p.label),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(p);
                      } else {
                        _selected.remove(p);
                      }
                    }),
                  )),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _EditPermissionsDialog extends StatefulWidget {
  final AppUser user;
  const _EditPermissionsDialog({required this.user});

  @override
  State<_EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<_EditPermissionsDialog> {
  late Set<Permission> _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.user.permissions.toSet();
  }

  Future<void> _save() async {
    setState(() => _submitting = true);
    await context.read<AuthProvider>().updatePermissions(widget.user.id, _selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permissions for ${widget.user.username}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Permission.values
              .map((p) => CheckboxListTile(
                    value: _selected.contains(p),
                    title: Text(p.label),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(p);
                      } else {
                        _selected.remove(p);
                      }
                    }),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _save,
          child: _submitting
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
