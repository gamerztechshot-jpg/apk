// features/dharma_store/models/order.dart

enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final OrderStatus status;
  final double totalAmount;
  final Map<String, dynamic> paymentInfo; // JSON containing payment details
  final Map<String, dynamic> address; // JSON containing delivery address
  final List<Map<String, dynamic>> items; // JSON array of ordered items
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.paymentInfo,
    required this.address,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      paymentInfo: Map<String, dynamic>.from(json['payment_info'] ?? {}),
      address: Map<String, dynamic>.from(json['address'] ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'status': status.name,
      'total_amount': totalAmount,
      'payment_info': paymentInfo,
      'address': address,
      'items': items,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    OrderStatus? status,
    double? totalAmount,
    Map<String, dynamic>? paymentInfo,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      address: address ?? this.address,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get paymentStatusDisplayName {
    final paymentStatus = paymentInfo['payment_status'] ?? 'pending';
    switch (paymentStatus) {
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Pending';
    }
  }

  String get fullAddress {
    final parts = [
      address['address_line_1'],
      address['address_line_2'],
      address['city'],
      address['state'],
      address['pincode'],
      address['country'],
    ].where((part) => part != null && part.toString().isNotEmpty);
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.userId == userId &&
        other.orderNumber == orderNumber &&
        other.status == status &&
        other.totalAmount == totalAmount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        orderNumber.hashCode ^
        status.hashCode ^
        totalAmount.hashCode;
  }
}
