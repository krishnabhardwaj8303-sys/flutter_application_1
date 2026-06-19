// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'book_service.dart';

const _kCyan = Color(0xFF00BCD4);
const _kCyanDark = Color(0xFF006064);
const _kCyanDeep = Color(0xFF00363A);
const _kCyanLight = Color(0xFFE0F7FA);
const _kBg = Color(0xFFF0FAFB);
const _kText = Color(0xFF003C47);
const _kMuted = Color(0xFF607D8B);

class CartScreen extends StatelessWidget {
  /// Optional: used when navigating from a non-item-based category's cart bar
  final List<Map<String, dynamic>>? preloadedLocalItems;
  final String? category;

  const CartScreen({super.key, this.preloadedLocalItems, this.category});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final items = preloadedLocalItems != null
            ? preloadedLocalItems!
                .map((e) => CartItem(
                      category: category ?? '',
                      subCategory: e['name'] as String,
                      name: e['name'] as String,
                      image: e['image'] as String? ?? '',
                      price: double.tryParse((e['price'] as String? ?? '')
                              .replaceAll(RegExp(r'[^\d.]'), '')) ??
                          0,
                      quantity: e['quantity'] as int? ?? 1,
                    ))
                .toList()
            : cart.items;

        final double total = items.fold(0, (s, i) => s + i.price * i.quantity);
        final double tax = total * 0.05;
        final double grand = total + tax;

        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kCyanDark,
            foregroundColor: Colors.white,
            elevation: 0,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Cart',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              Text('${items.length} service${items.length != 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
            actions: [
              if (items.isNotEmpty && preloadedLocalItems == null)
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('Clear Cart?'),
                        content: const Text('Remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style: TextStyle(color: _kMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              cart.clear();
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Clear',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
            ],
          ),
          body: items.isEmpty
              ? _EmptyCart(onShop: () => Navigator.pop(context))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _CartItemTile(
                          item: items[i],
                          isGlobal: preloadedLocalItems == null,
                          onAdd: preloadedLocalItems == null
                              ? () {
                                  HapticFeedback.selectionClick();
                                  cart.addItem(CartItem(
                                    category: items[i].category,
                                    subCategory: items[i].subCategory,
                                    name: items[i].name,
                                    image: items[i].image,
                                    price: items[i].price,
                                  ));
                                }
                              : null,
                          onRemove: preloadedLocalItems == null
                              ? () {
                                  HapticFeedback.selectionClick();
                                  cart.removeItem(items[i].key);
                                }
                              : null,
                          onDelete: preloadedLocalItems == null
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  cart.deleteItem(items[i].key);
                                }
                              : null,
                        ),
                      ),
                    ),
                    _BillSummary(subtotal: total, tax: tax, grand: grand),
                    _CheckoutBar(
                      grand: grand,
                      onAddMore: () => Navigator.pop(context),
                      onCheckout: () {
                        final allItems = items
                            .map((e) => {
                                  'name': e.name,
                                  'image': e.image,
                                  'price': '₹${e.price.toStringAsFixed(0)}',
                                  'quantity': e.quantity,
                                  'category': e.category,
                                })
                            .toList();

                        // Group by primary category for BookServiceScreen
                        final primaryCategory = items.first.category;
                        final subCategories =
                            items.map((e) => e.name).join(', ');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookServiceScreen(
                              category: primaryCategory,
                              subCategory: subCategories,
                              serviceName: '',
                              selectedItems: allItems,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Cart Item Tile ────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isGlobal;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDelete;

  const _CartItemTile({
    required this.item,
    required this.isGlobal,
    this.onAdd,
    this.onRemove,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final itemTotal = item.price * item.quantity;

    return Dismissible(
      key: Key(item.key),
      direction: isGlobal ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.shade50, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 26),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCF0F4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                item.image,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: _kCyanLight,
                    child: const Icon(Icons.home_repair_service_rounded,
                        color: _kCyan, size: 28)),
              ),
            ),
            const SizedBox(width: 12),
            // Name + category
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kText)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: _kCyanLight,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(item.category,
                          style: const TextStyle(
                              color: _kCyanDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    if (item.price > 0)
                      Text(
                        item.quantity > 1
                            ? '₹${item.price.toStringAsFixed(0)} × ${item.quantity} = ₹${itemTotal.toStringAsFixed(0)}'
                            : '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: _kCyanDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      )
                    else
                      const Text('Price on booking',
                          style: TextStyle(color: _kMuted, fontSize: 11)),
                  ]),
            ),
            const SizedBox(width: 8),
            // Quantity controls
            if (isGlobal)
              Column(mainAxisSize: MainAxisSize.min, children: [
                _QtyBtn(icon: Icons.add_rounded, onTap: onAdd ?? () {}),
                const SizedBox(height: 4),
                Text('${item.quantity}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _kText)),
                const SizedBox(height: 4),
                _QtyBtn(
                    icon: item.quantity == 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    onTap: item.quantity == 1
                        ? (onDelete ?? () {})
                        : (onRemove ?? () {}),
                    isDelete: item.quantity == 1),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDelete;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDelete ? Colors.red.shade50 : _kCyanLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDelete
                  ? Colors.red.shade200
                  : const Color(0xFF80DEEA).withOpacity(0.5)),
        ),
        child: Icon(icon, size: 15, color: isDelete ? Colors.red : _kCyanDark),
      ),
    );
  }
}

// ─── Bill Summary ──────────────────────────────────────────────
class _BillSummary extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double grand;

  const _BillSummary(
      {required this.subtotal, required this.tax, required this.grand});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCF0F4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(children: [
        _BillRow(label: 'Subtotal', value: '₹${subtotal.toStringAsFixed(0)}'),
        const SizedBox(height: 8),
        _BillRow(
            label: 'Platform fee (5%)',
            value: '₹${tax.toStringAsFixed(0)}',
            muted: true),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: Color(0xFFE0F2F4), height: 1),
        ),
        _BillRow(
          label: 'Total Payable',
          value: '₹${grand.toStringAsFixed(0)}',
          bold: true,
          valueColor: _kCyanDark,
        ),
      ]),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool muted;
  final Color? valueColor;

  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: muted ? _kMuted : _kText)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: valueColor ?? (muted ? _kMuted : _kText))),
      ],
    );
  }
}

// ─── Checkout Bar ──────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  final double grand;
  final VoidCallback onAddMore;
  final VoidCallback onCheckout;

  const _CheckoutBar({
    required this.grand,
    required this.onAddMore,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      color: Colors.white,
      child: Row(children: [
        // Add more
        GestureDetector(
          onTap: onAddMore,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: _kCyanLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF80DEEA).withOpacity(0.6))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: _kCyanDark, size: 18),
              SizedBox(width: 4),
              Text('Add More',
                  style: TextStyle(
                      color: _kCyanDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        // Proceed to book
        Expanded(
          child: GestureDetector(
            onTap: onCheckout,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kCyanDark, _kCyan],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _kCyan.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  grand > 0
                      ? 'Proceed · ₹${grand.toStringAsFixed(0)}'
                      : 'Confirm Booking',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Empty Cart ────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🛒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Your cart is empty',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
        const SizedBox(height: 8),
        const Text('Add services to get started',
            style: TextStyle(color: _kMuted, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onShop,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Browse Services'),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kCyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
        ),
      ]),
    );
  }
}
