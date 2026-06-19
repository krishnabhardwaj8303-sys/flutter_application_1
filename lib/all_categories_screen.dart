import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_service.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const Color kCyan = Color(0xFF06B6D4);
const Color kCyanDark = Color(0xFF0891B2);
const Color kBg = Color(0xFFF4FCFF);
const Color kTextDark = Color(0xFF0F172A);

// ─────────────────────────────────────────────
// CATEGORY MODEL
// ─────────────────────────────────────────────
class CategoryModel {
  final String name;
  final IconData icon;
  final int price;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.price,
  });
}

const List<CategoryModel> categories = [
  CategoryModel(
    name: 'Electrician',
    icon: Icons.electrical_services_rounded,
    price: 199,
  ),
  CategoryModel(
    name: 'Plumber',
    icon: Icons.plumbing_rounded,
    price: 149,
  ),
  CategoryModel(
    name: 'Cleaning',
    icon: Icons.cleaning_services_rounded,
    price: 499,
  ),
  CategoryModel(
    name: 'Carpenter',
    icon: Icons.handyman_rounded,
    price: 299,
  ),
  CategoryModel(
    name: 'Painter',
    icon: Icons.format_paint_rounded,
    price: 599,
  ),
  CategoryModel(
    name: 'AC Repair',
    icon: Icons.ac_unit_rounded,
    price: 349,
  ),
  CategoryModel(
    name: 'Salon',
    icon: Icons.content_cut_rounded,
    price: 199,
  ),
  CategoryModel(
    name: 'Laundry',
    icon: Icons.local_laundry_service_rounded,
    price: 149,
  ),
  CategoryModel(
    name: 'Appliance',
    icon: Icons.build_rounded,
    price: 249,
  ),
];

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String search = '';

  final Map<String, int> availability = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAvailability();
  }

  // ─────────────────────────────────────────────
  // LOAD WORKERS
  // ─────────────────────────────────────────────
  Future<void> loadAvailability() async {
    try {
      for (final cat in categories) {
        final snap = await FirebaseFirestore.instance
            .collection('workers')
            .where('isOnline', isEqualTo: true)
            .where('services', arrayContains: cat.name)
            .get();

        availability[cat.name] = snap.docs.length;
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // FILTER
  // ─────────────────────────────────────────────
  List<CategoryModel> get filteredCategories {
    return categories.where((cat) {
      return cat.name.toLowerCase().contains(search.toLowerCase());
    }).toList();
  }

  // ─────────────────────────────────────────────
  // OPEN SERVICE
  // ─────────────────────────────────────────────
  void openCategory(CategoryModel cat) {
    final count = availability[cat.name] ?? 0;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workers available right now'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookServiceScreen(
          category: cat.name,
          subCategory: cat.name,
          serviceName: cat.name,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // ───────────────── APP BAR ─────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        title: const Text(
          'All Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // ───────────────── SEARCH ─────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  setState(() {
                    search = v;
                  });
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search service...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: kCyanDark,
                  ),
                  suffixIcon: search.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              search = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // ───────────────── LIST ─────────────────
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kCyan,
                    ),
                  )
                : filteredCategories.isEmpty
                    ? const Center(
                        child: Text(
                          'No services found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredCategories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.90,
                        ),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];

                          final count = availability[cat.name] ?? 0;

                          final available = count > 0;

                          return GestureDetector(
                            onTap: () => openCategory(cat),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ICON
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: kCyan.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      color: kCyanDark,
                                      size: 34,
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // NAME
                                  Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: kTextDark,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // PRICE
                                  Text(
                                    'Starting ₹${cat.price}',
                                    style: const TextStyle(
                                      color: kCyanDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // STATUS
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: available
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      available
                                          ? '$count workers available'
                                          : 'Unavailable',
                                      style: TextStyle(
                                        color: available
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
