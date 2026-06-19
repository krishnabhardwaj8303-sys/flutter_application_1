// TODO Implement this library.
// service_prices.dart
// ─────────────────────────────────────────────
//  SHARED PRICE MAP
//  Import this in both book_service.dart and wherever SubCategoryScreen is called.
// ─────────────────────────────────────────────

const Map<String, double> kPriceMap = {
  'Fan Repair': 199,
  'Fan Installation': 249,
  'Wiring': 299,
  'AC Installation': 200,
  'AC Repair': 2000,
  'Almary Making': 1999,
  'Tap Repair': 149,
  'Pipeline Repair': 249,
  'Home Cleaning': 0,
  "Basin Installation": 209,
  "Bathroom Accessories Installation": 309,
  "Flush Tank Installation": 199,
  "Jet Spray Repair": 109,
  "Shower Installation": 299,
  "Shower Repair and Replacement": 209,
  "Sink Installation": 209,
  "Toilet Seat Cover Replacement": 159,
  "Waste Pipe Replacement": 299,
  "Water Tank Installation": 399,
  "Western Toilet Seat Replacement": 499,
  "Flush Tank Repair": 199,
  'Light Installation': 209,
  'Switch and Socket Installation': 299,
  'MCB replacement': 289,
  'Tv Installation': 199,
  'Fan Replacement': 209,
  'Switch Replacement': 249,
  'Socket Replacement': 299,
  'Board Installation': 199,
  'Holder Installation': 309,
  'Wall/Celling Light Replacement': 309,
  'Doorbell Replacement': 209,
  'Doorbell Installation': 199,
  'Geyser Installation': 309,
  'Washing Machine Repairing': 209,
  'Refrigerator Repairing': 309,
  'Camera Installation': 399,
  'Refrigerator Gas Filling': 299,
  "Bathroom Cleaning": 0,
  "Kitchen Cleaning": 0,
  "Water Tank Cleaning": 299,
  "Deep Cleaning": 0,
  "Vehicle Cleaning": 0,
  "Refrigerator Cleaning": 0,
  "Shop Cleaning": 0,
  "Gas Refill": 299,
  "Water Leaking": 299,
  "Compressor Change": 399,
  "AC Moving": 209,
  "BookShelf": 599,
  "Door and Window": 499,
  "Chair and Table": 599,
  "Almary": 599,
  "Bed": 599,
  "Screen Changing": 149,
  "Phone Exchange": 100,
  "Full Phone Repairing": 1499,
  "Speaker Repairing": 399,
  "Party Boy/Girl": 400,
  "Wedding Boy/Girl": 499,
  "Cafe Staff": 400,
  "Hotel Staff": 599,
  "Shop Staff": 499,
  "Pressing": 30,
  "Drying": 30,
  "Cleaning": 30,
  "Full House": 699,
  "One Room": 399,
  "Window And Door": 299,
  "Ceiling Painting": 499,
  "Hair Cut": 60,
  "Hair Wash": 69,
  "Makeup": 299,
  "Stitching": 199,
  "Alteration": 149,
  "Blouse Stitching": 179,
  "Suit Stitching": 499,
  "Kids Dress": 149,
  "House Maid": 299,
  "Child Care Maid": 299,
  "Kitchen Maid": 299,
};

// ─────────────────────────────────────────────
//  HELPER: build a subList for SubCategoryScreen
//  with prices injected from kPriceMap.
//
//  Usage:
//    final subList = buildSubList(
//      names: ['Fan Repair', 'Fan Installation'],
//      imageMap: {'Fan Repair': 'assets/fan.webp', ...},
//      descMap:  {'Fan Repair': 'Fix ceiling/wall fans', ...},
//    );
// ─────────────────────────────────────────────
List<Map<String, String>> buildSubList({
  required List<String> names,
  required Map<String, String> imageMap,
  Map<String, String>? descMap,
}) {
  return names.map((name) {
    final price = kPriceMap[name];
    final priceStr = (price == null || price == 0)
        ? '' // cleaning categories have item-based pricing, show nothing
        : '₹${price.toStringAsFixed(0)}';
    return {
      'name': name,
      'image': imageMap[name] ?? 'assets/default.webp',
      'price': priceStr,
      'desc': descMap?[name] ?? '',
    };
  }).toList();
}
