// features/dharma_store/models/cart_item.dart
class CartItem {
  final String id;
  final String itemId;
  final String nameEn;
  final String nameHi;
  final double price;
  final String? imageUrl;
  final int quantity;
  final String? size;
  final String? color;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.itemId,
    required this.nameEn,
    required this.nameHi,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.size,
    this.color,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameHi: json['name_hi'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 1,
      size: json['size'],
      color: json['color'],
      addedAt: DateTime.tryParse(json['added_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'name_en': nameEn,
      'name_hi': nameHi,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
      'size': size,
      'color': color,
      'added_at': addedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    String? itemId,
    String? nameEn,
    String? nameHi,
    double? price,
    String? imageUrl,
    int? quantity,
    String? size,
    String? color,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      color: color ?? this.color,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => price * quantity;

  @override
  String toString() {
    return 'CartItem(id: $id, itemId: $itemId, nameEn: $nameEn, nameHi: $nameHi, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
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
