// features/dharma_store/models/order_item.dart
class OrderItem {
  final String id;
  final String itemId;
  final String nameEn;
  final String nameHi;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? size;
  final String? color;

  OrderItem({
    required this.id,
    required this.itemId,
    required this.nameEn,
    required this.nameHi,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.size,
    this.color,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameHi: json['name_hi'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['image_url'],
      size: json['size'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'name_en': nameEn,
      'name_hi': nameHi,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'size': size,
      'color': color,
    };
  }

  OrderItem copyWith({
    String? id,
    String? itemId,
    String? nameEn,
    String? nameHi,
    double? price,
    int? quantity,
    String? imageUrl,
    String? size,
    String? color,
  }) {
    return OrderItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }

  double get totalPrice => price * quantity;

  @override
  String toString() {
    return 'OrderItem(id: $id, itemId: $itemId, nameEn: $nameEn, nameHi: $nameHi, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem &&
        other.id == id &&
        other.itemId == itemId &&
        other.nameEn == nameEn &&
        other.nameHi == nameHi &&
        other.price == price &&
        other.quantity == quantity &&
        other.size == size &&
        other.color == color;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        itemId.hashCode ^
        nameEn.hashCode ^
        nameHi.hashCode ^
        price.hashCode ^
        quantity.hashCode ^
        size.hashCode ^
        color.hashCode;
  }
}
