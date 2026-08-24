enum UserRole { admin, staff }

extension UserRoleX on UserRole {
  String get key => this == UserRole.admin ? 'admin' : 'staff';
  String get label => this == UserRole.admin ? 'Admin' : 'Staff';
  static UserRole fromKey(String? k) => k == 'admin' ? UserRole.admin : UserRole.staff;
}

/// Public identity of a logged-in person. Never carries the password.
class AppUser {
  final String id;
  final String name;

  /// Display handle — the owner's phone number, or a staff member's email.
  final String username;
  final UserRole role;

  /// Whether this person can add/edit data. Admins always can.
  final bool canEdit;

  /// The shop this person belongs to (Firebase custom claim `shopId`).
  /// For an admin this equals [id] (they own their own shop). For staff this
  /// is the owner's uid, which differs from the staff member's own [id].
  /// Falls back to [id] when unset, so older local-only accounts still work.
  final String? shopId;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.canEdit = true,
    this.shopId,
  });

  bool get isAdmin => role == UserRole.admin;

  String get effectiveShopId => shopId ?? id;

  AppUser copyWith({String? name, String? username, UserRole? role, bool? canEdit, String? shopId}) => AppUser(
        id: id,
        name: name ?? this.name,
        username: username ?? this.username,
        role: role ?? this.role,
        canEdit: canEdit ?? this.canEdit,
        shopId: shopId ?? this.shopId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'username': username,
        'role': role.key,
        'canEdit': canEdit,
        'shopId': shopId,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        name: m['name'] as String,
        username: m['username'] as String,
        role: UserRoleX.fromKey(m['role'] as String?),
        canEdit: m['canEdit'] as bool? ?? true,
        shopId: m['shopId'] as String?,
      );
}
