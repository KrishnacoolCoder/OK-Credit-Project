import 'package:flutter/foundation.dart';

enum BillStatus { unpaid, paid, voided }

class BillItem {
  final String id;
  final String name;
  final double rate;
  final double quantity;

  const BillItem({
    required this.id,
    required this.name,
    required this.rate,
    required this.quantity,
  });

  double get total => rate * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'quantity': quantity,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Bill {
  final String id;
  final String customerName;
  final String? customerPhone;
  final List<BillItem> items;
  final double discount;
  final double deliveryCharge;
  final DateTime date;
  final BillStatus status;
  final String templateId;

  const Bill({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.items,
    this.discount = 0.0,
    this.deliveryCharge = 0.0,
    required this.date,
    this.status = BillStatus.unpaid,
    this.templateId = 'default',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => (subtotal + deliveryCharge) - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((x) => x.toMap()).toList(),
      'discount': discount,
      'deliveryCharge': deliveryCharge,
      'date': date.millisecondsSinceEpoch,
      'status': status.name,
      'templateId': templateId,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'],
      items: List<BillItem>.from(
        (map['items'] as List? ?? []).map<BillItem>((x) => BillItem.fromMap(x as Map<String, dynamic>)),
      ),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      status: BillStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BillStatus.unpaid,
      ),
      templateId: map['templateId'] ?? 'default',
    );
  }
}
