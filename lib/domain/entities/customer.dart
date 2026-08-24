class Customer {
  final String id;
  final String name;
  final String? phone;
  final double? creditLimit;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.creditLimit,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Customer copyWith({String? id, String? name, String? phone, double? creditLimit, DateTime? createdAt}) =>
    Customer(
      id: id ?? this.id, name: name ?? this.name,
      phone: phone ?? this.phone, creditLimit: creditLimit ?? this.creditLimit,
      createdAt: createdAt ?? this.createdAt,
    );
}
