/// Individual permissions that can be granted to a non-admin user.
/// The admin account always has every permission implicitly.
enum Permission {
  manageInvoices,
  manageReceipts,
  manageCompanyProfile,
  manageUsers,
}

extension PermissionLabel on Permission {
  String get label {
    switch (this) {
      case Permission.manageInvoices:
        return 'Create & edit invoices';
      case Permission.manageReceipts:
        return 'View & create receipts';
      case Permission.manageCompanyProfile:
        return 'Edit company profile';
      case Permission.manageUsers:
        return 'Manage users & permissions';
    }
  }
}

class AppUser {
  final String id;
  String username;

  /// SHA-256 hash of the password (hex-encoded). Never store plain text.
  String passwordHash;

  /// The built-in admin account (SJTRACKING) always has every permission
  /// and cannot have them revoked or be deleted.
  bool isAdmin;

  Set<Permission> permissions;

  /// Self-signed-up accounts start unapproved and cannot log in until an
  /// admin approves them. Admin-created accounts and the built-in admin
  /// are approved automatically.
  bool isApproved;

  DateTime createdAt;

  AppUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    this.isAdmin = false,
    Set<Permission>? permissions,
    bool? isApproved,
    DateTime? createdAt,
  })  : permissions = permissions ?? <Permission>{},
        isApproved = isApproved ?? isAdmin,
        createdAt = createdAt ?? DateTime.now();

  bool hasPermission(Permission p) => isAdmin || permissions.contains(p);

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'isAdmin': isAdmin,
        'permissions': permissions.map((p) => p.name).toList(),
        'isApproved': isApproved,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String? ?? '',
        passwordHash: json['passwordHash'] as String? ?? '',
        isAdmin: json['isAdmin'] as bool? ?? false,
        permissions: ((json['permissions'] as List<dynamic>?) ?? [])
            .map((name) => Permission.values.firstWhere(
                  (p) => p.name == name,
                  orElse: () => Permission.manageInvoices,
                ))
            .toSet(),
        isApproved: json['isApproved'] as bool? ?? (json['isAdmin'] as bool? ?? false),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
