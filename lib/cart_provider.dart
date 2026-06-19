// lib/cart_provider.dart
import 'package:flutter/foundation.dart';

class CartItem {
  final String category;
  final String subCategory;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.category,
    required this.subCategory,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  // Unique key so same service from same subcategory merges
  String get key => '$category||$subCategory||$name';

  Map<String, dynamic> toMap() => {
        'category': category,
        'subCategory': subCategory,
        'name': name,
        'image': image,
        'price': price,
        'quantity': quantity,
      };
}

class CartProvider extends ChangeNotifier {
  static final CartProvider _instance = CartProvider._internal();
  factory CartProvider() => _instance;
  CartProvider._internal();

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalCount => _items.values.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice =>
      _items.values.fold(0, (sum, i) => sum + i.price * i.quantity);

  bool get isEmpty => _items.isEmpty;

  int quantityOf(String key) => _items[key]?.quantity ?? 0;

  void addItem(CartItem item) {
    if (_items.containsKey(item.key)) {
      _items[item.key]!.quantity++;
    } else {
      _items[item.key] = item;
    }
    notifyListeners();
  }

  void removeItem(String key) {
    if (!_items.containsKey(key)) return;
    if (_items[key]!.quantity > 1) {
      _items[key]!.quantity--;
    } else {
      _items.remove(key);
    }
    notifyListeners();
  }

  void deleteItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
