// lib/subcategory_screen.dart
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';
import 'service_prices.dart';

// ─── Design tokens ────────────────────────────────────────────
const _kCyan = Color(0xFF00BCD4);
const _kCyanDark = Color(0xFF006064);
const _kCyanDeep = Color(0xFF00363A);
const _kCyanLight = Color(0xFFE0F7FA);
const _kCyanMid = Color(0xFF80DEEA);
const _kBg = Color(0xFFF0FAFB);
const _kCard = Colors.white;
const _kText = Color(0xFF003C47);
const _kSubText = Color(0xFF607D8B);

// ─── Category aliases ─────────────────────────────────────────
const Map<String, List<String>> _kCategoryAliases = {
  "Cleaning": ["cleaning", "Cleaning"],
  "Electrician": ["electrician", "Electrician"],
  "Plumber": ["plumber", "Plumber"],
  "Carpenter": ["carpenter", "Carpenter"],
  "AC Repair": ["ac repair", "AC Repair", "AC repair", "ac_repair"],
  "Maid": ["maid", "Maid"],
  "Phone Repairing": ["phone repairing", "Phone Repairing", "phone_repairing"],
  "Salon": ["salon", "Salon"],
  "Painter": ["painter", "Painter"],
  "Laundry and Dry Cleaning": [
    "laundry and dry cleaning",
    "Laundry and Dry Cleaning",
    "laundry",
    "dry cleaning",
  ],
  "Staff(Boy/Girls)": [
    "staff",
    "Staff",
    "Staff(Boy/Girls)",
    "staff(boy/girls)",
  ],
  "Tailor": ["tailor", "Tailor"],
};

// ─── Item-based categories (use global CartProvider) ──────────
const Set<String> _kItemBasedCategories = {
  'Cleaning',
  'Electrician',
  'Plumber',
  'AC Repair',
  'Carpenter',
  'Painter',
  'Salon',
  'Tailor',
  'Laundry and Dry Cleaning',
  'Maid',
};

// ─── Nested items per subcategory ────────────────────────────
const Map<String, Map<String, List<Map<String, dynamic>>>> _kNestedItems = {
  'Electrician': {
    'Fan Repair': [
      {
        'name': 'Ceiling Fan',
        'image': 'assets/fan repair.webp',
        'price': 199.0,
        'unit': 'per fan'
      },
      {
        'name': 'Exhaust Fan',
        'image': 'assets/fan repair.webp',
        'price': 149.0,
        'unit': 'per fan'
      },
      {
        'name': 'Table Fan',
        'image': 'assets/fan repair.webp',
        'price': 129.0,
        'unit': 'per fan'
      },
    ],
    'Fan Installation': [
      {
        'name': 'Ceiling Fan',
        'image': 'assets/fan installation.webp',
        'price': 249.0,
        'unit': 'per fan'
      },
      {
        'name': 'Exhaust Fan',
        'image': 'assets/fan installation.webp',
        'price': 199.0,
        'unit': 'per fan'
      },
    ],
    'Fan Replacement': [
      {
        'name': 'Ceiling Fan',
        'image': 'assets/fan replacement.webp',
        'price': 209.0,
        'unit': 'per fan'
      },
      {
        'name': 'Exhaust Fan',
        'image': 'assets/fan replacement.webp',
        'price': 169.0,
        'unit': 'per fan'
      },
    ],
    'Wiring': [
      {
        'name': 'Single Room Wiring',
        'image': 'assets/Wiring.webp',
        'price': 299.0,
        'unit': 'per room'
      },
      {
        'name': 'Full House Wiring',
        'image': 'assets/Wiring.webp',
        'price': 999.0,
        'unit': 'flat'
      },
      {
        'name': 'Wire Extension',
        'image': 'assets/Wiring.webp',
        'price': 149.0,
        'unit': 'per point'
      },
    ],
    'Light Installation': [
      {
        'name': 'LED Bulb / Tube',
        'image': 'assets/light replacement.webp',
        'price': 99.0,
        'unit': 'per light'
      },
      {
        'name': 'Ceiling Light',
        'image': 'assets/ceiling light.webp',
        'price': 149.0,
        'unit': 'per light'
      },
      {
        'name': 'Wall Light',
        'image': 'assets/light replacement.webp',
        'price': 129.0,
        'unit': 'per light'
      },
      {
        'name': 'Spotlight / Downlight',
        'image': 'assets/light replacement.webp',
        'price': 179.0,
        'unit': 'per light'
      },
    ],
    'Switch and Socket Installation': [
      {
        'name': 'Switch',
        'image': 'assets/switch.webp',
        'price': 99.0,
        'unit': 'per switch'
      },
      {
        'name': 'Socket / Plug Point',
        'image': 'assets/ss.webp',
        'price': 119.0,
        'unit': 'per socket'
      },
      {
        'name': 'USB Socket',
        'image': 'assets/ss.webp',
        'price': 149.0,
        'unit': 'per socket'
      },
    ],
    'Switch Replacement': [
      {
        'name': 'Single Switch',
        'image': 'assets/switch.webp',
        'price': 99.0,
        'unit': 'per switch'
      },
      {
        'name': 'Double Switch',
        'image': 'assets/switch.webp',
        'price': 149.0,
        'unit': 'per board'
      },
      {
        'name': 'Modular Switch',
        'image': 'assets/switch.webp',
        'price': 179.0,
        'unit': 'per switch'
      },
    ],
    'Socket Replacement': [
      {
        'name': 'Standard Socket',
        'image': 'assets/ss.webp',
        'price': 119.0,
        'unit': 'per socket'
      },
      {
        'name': 'Heavy Duty Socket',
        'image': 'assets/ss.webp',
        'price': 149.0,
        'unit': 'per socket'
      },
    ],
    'MCB replacement': [
      {
        'name': 'Single MCB',
        'image': 'assets/MCB replacement.webp',
        'price': 199.0,
        'unit': 'per MCB'
      },
      {
        'name': 'Double MCB',
        'image': 'assets/MCB replacement.webp',
        'price': 279.0,
        'unit': 'per MCB'
      },
      {
        'name': 'Full MCB Board',
        'image': 'assets/MCB replacement.webp',
        'price': 499.0,
        'unit': 'flat'
      },
    ],
    'Tv Installation': [
      {
        'name': 'Wall Mount Installation',
        'image': 'assets/Tv installation.webp',
        'price': 199.0,
        'unit': 'per TV'
      },
      {
        'name': 'Cable Management',
        'image': 'assets/Tv installation.webp',
        'price': 99.0,
        'unit': 'flat'
      },
      {
        'name': 'Set Top Box Setup',
        'image': 'assets/Tv installation.webp',
        'price': 149.0,
        'unit': 'per device'
      },
    ],
    'Board Installation': [
      {
        'name': 'Switch Board (2 module)',
        'image': 'assets/switch board.webp',
        'price': 199.0,
        'unit': 'per board'
      },
      {
        'name': 'Switch Board (4 module)',
        'image': 'assets/switch board.webp',
        'price': 249.0,
        'unit': 'per board'
      },
      {
        'name': 'Switch Board (6 module)',
        'image': 'assets/switch board.webp',
        'price': 299.0,
        'unit': 'per board'
      },
    ],
    'Holder Replacement': [
      {
        'name': 'Bulb Holder',
        'image': 'assets/holder replacement.webp',
        'price': 99.0,
        'unit': 'per holder'
      },
      {
        'name': 'Tube Light Holder',
        'image': 'assets/holder replacement.webp',
        'price': 129.0,
        'unit': 'per holder'
      },
    ],
    'Wall/Ceiling Light Replacement': [
      {
        'name': 'Wall Light',
        'image': 'assets/ceiling light.webp',
        'price': 149.0,
        'unit': 'per light'
      },
      {
        'name': 'Ceiling Light',
        'image': 'assets/ceiling light.webp',
        'price': 179.0,
        'unit': 'per light'
      },
      {
        'name': 'Chandelier',
        'image': 'assets/ceiling light.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
    ],
    'Doorbell Installation': [
      {
        'name': 'Wired Doorbell',
        'image': 'assets/Doorbell.webp',
        'price': 199.0,
        'unit': 'flat'
      },
      {
        'name': 'Wireless Doorbell',
        'image': 'assets/Doorbell.webp',
        'price': 149.0,
        'unit': 'flat'
      },
      {
        'name': 'Video Doorbell',
        'image': 'assets/Doorbell.webp',
        'price': 299.0,
        'unit': 'flat'
      },
    ],
    'Doorbell Replacement': [
      {
        'name': 'Wired Doorbell',
        'image': 'assets/Doorbell.webp',
        'price': 179.0,
        'unit': 'flat'
      },
      {
        'name': 'Wireless Doorbell',
        'image': 'assets/Doorbell.webp',
        'price': 129.0,
        'unit': 'flat'
      },
    ],
    'Geyser Installation': [
      {
        'name': 'Electric Geyser (upto 15L)',
        'image': 'assets/geyser.webp',
        'price': 299.0,
        'unit': 'flat'
      },
      {
        'name': 'Electric Geyser (25L+)',
        'image': 'assets/geyser.webp',
        'price': 349.0,
        'unit': 'flat'
      },
      {
        'name': 'Instant Geyser',
        'image': 'assets/geyser.webp',
        'price': 249.0,
        'unit': 'flat'
      },
    ],
    'Washing Machine Repairing': [
      {
        'name': 'Semi-Automatic',
        'image': 'assets/washing machine.webp',
        'price': 299.0,
        'unit': 'per visit'
      },
      {
        'name': 'Fully Automatic (Top Load)',
        'image': 'assets/washing machine.webp',
        'price': 349.0,
        'unit': 'per visit'
      },
      {
        'name': 'Fully Automatic (Front Load)',
        'image': 'assets/washing machine.webp',
        'price': 399.0,
        'unit': 'per visit'
      },
    ],
    'Refrigerator Repairing': [
      {
        'name': 'Single Door',
        'image': 'assets/Refrigerator.webp',
        'price': 299.0,
        'unit': 'per visit'
      },
      {
        'name': 'Double Door',
        'image': 'assets/Refrigerator.webp',
        'price': 349.0,
        'unit': 'per visit'
      },
      {
        'name': 'Side-by-Side',
        'image': 'assets/Refrigerator.webp',
        'price': 449.0,
        'unit': 'per visit'
      },
    ],
    'Camera Installation': [
      {
        'name': 'CCTV Camera',
        'image': 'assets/camera.webp',
        'price': 399.0,
        'unit': 'per camera'
      },
      {
        'name': 'DVR Setup',
        'image': 'assets/camera.webp',
        'price': 299.0,
        'unit': 'flat'
      },
      {
        'name': 'Full Kit (4 cam)',
        'image': 'assets/camera.webp',
        'price': 999.0,
        'unit': 'flat'
      },
    ],
    'Refrigerator Gas Filling': [
      {
        'name': 'Single Door (R600a)',
        'image': 'assets/Refrigerator gas.webp',
        'price': 299.0,
        'unit': 'flat'
      },
      {
        'name': 'Double Door (R134a)',
        'image': 'assets/Refrigerator gas.webp',
        'price': 399.0,
        'unit': 'flat'
      },
    ],
  },
  'Plumber': {
    'Tap Repair': [
      {
        'name': 'Kitchen Tap',
        'image': 'assets/tap repair.webp',
        'price': 149.0,
        'unit': 'per tap'
      },
      {
        'name': 'Bathroom Tap',
        'image': 'assets/tap repair.webp',
        'price': 149.0,
        'unit': 'per tap'
      },
      {
        'name': 'Mixer Tap',
        'image': 'assets/tap repair.webp',
        'price': 199.0,
        'unit': 'per tap'
      },
      {
        'name': 'Outdoor Tap',
        'image': 'assets/tap repair.webp',
        'price': 129.0,
        'unit': 'per tap'
      },
    ],
    'Pipeline Repair': [
      {
        'name': 'Minor Leak Fix',
        'image': 'assets/pipeline repair.webp',
        'price': 199.0,
        'unit': 'per point'
      },
      {
        'name': 'Pipe Burst Repair',
        'image': 'assets/pipeline repair.webp',
        'price': 349.0,
        'unit': 'per point'
      },
      {
        'name': 'Pipe Replacement (1m)',
        'image': 'assets/pipeline repair.webp',
        'price': 249.0,
        'unit': 'per metre'
      },
      {
        'name': 'Joint Sealing',
        'image': 'assets/pipeline repair.webp',
        'price': 149.0,
        'unit': 'per joint'
      },
    ],
    'Basin Installation': [
      {
        'name': 'Wall-hung Basin',
        'image': 'assets/Basin installation.webp',
        'price': 299.0,
        'unit': 'per basin'
      },
      {
        'name': 'Pedestal Basin',
        'image': 'assets/Basin installation.webp',
        'price': 349.0,
        'unit': 'per basin'
      },
      {
        'name': 'Counter-top Basin',
        'image': 'assets/Basin installation.webp',
        'price': 399.0,
        'unit': 'per basin'
      },
    ],
    'Bathroom Accessories Installation': [
      {
        'name': 'Towel Rod',
        'image': 'assets/Bathroom accessories installation.webp',
        'price': 99.0,
        'unit': 'per rod'
      },
      {
        'name': 'Soap Dish',
        'image': 'assets/Bathroom accessories installation.webp',
        'price': 79.0,
        'unit': 'per unit'
      },
      {
        'name': 'Toilet Paper Holder',
        'image': 'assets/Bathroom accessories installation.webp',
        'price': 89.0,
        'unit': 'per unit'
      },
      {
        'name': 'Mirror with shelf',
        'image': 'assets/Bathroom accessories installation.webp',
        'price': 199.0,
        'unit': 'per unit'
      },
      {
        'name': 'Shower Curtain Rod',
        'image': 'assets/Bathroom accessories installation.webp',
        'price': 149.0,
        'unit': 'per rod'
      },
    ],
    'Flush Tank Installation': [
      {
        'name': 'Standard Flush Tank',
        'image': 'assets/flush tank installation.webp',
        'price': 199.0,
        'unit': 'per unit'
      },
      {
        'name': 'Concealed Flush Tank',
        'image': 'assets/flush tank installation.webp',
        'price': 299.0,
        'unit': 'per unit'
      },
      {
        'name': 'Dual Flush System',
        'image': 'assets/flush tank installation.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
    ],
    'Flush Tank Repair': [
      {
        'name': 'Float Valve Repair',
        'image': 'assets/flush tank repair.webp',
        'price': 149.0,
        'unit': 'per unit'
      },
      {
        'name': 'Flush Button Repair',
        'image': 'assets/flush tank repair.webp',
        'price': 129.0,
        'unit': 'per unit'
      },
      {
        'name': 'Full Tank Service',
        'image': 'assets/flush tank repair.webp',
        'price': 199.0,
        'unit': 'per unit'
      },
    ],
    'Jet Spray Repair': [
      {
        'name': 'Jet Spray Nozzle',
        'image': 'assets/jet spray repair.webp',
        'price': 99.0,
        'unit': 'per unit'
      },
      {
        'name': 'Hose Pipe Repair',
        'image': 'assets/jet spray repair.webp',
        'price': 109.0,
        'unit': 'per unit'
      },
      {
        'name': 'Full Assembly Replace',
        'image': 'assets/jet spray repair.webp',
        'price': 149.0,
        'unit': 'per unit'
      },
    ],
    'Shower Installation': [
      {
        'name': 'Overhead Shower',
        'image': 'assets/shower installation.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
      {
        'name': 'Hand Shower',
        'image': 'assets/shower installation.webp',
        'price': 199.0,
        'unit': 'per unit'
      },
      {
        'name': 'Rain Shower Head',
        'image': 'assets/shower installation.webp',
        'price': 349.0,
        'unit': 'per unit'
      },
    ],
    'Shower Repair and Replacement': [
      {
        'name': 'Overhead Shower',
        'image': 'assets/shower installation.webp',
        'price': 199.0,
        'unit': 'per unit'
      },
      {
        'name': 'Hand Shower',
        'image': 'assets/shower installation.webp',
        'price': 179.0,
        'unit': 'per unit'
      },
      {
        'name': 'Shower Valve',
        'image': 'assets/shower installation.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
    ],
    'Sink Installation': [
      {
        'name': 'Kitchen Sink (single)',
        'image': 'assets/Sink installation.webp',
        'price': 249.0,
        'unit': 'per sink'
      },
      {
        'name': 'Kitchen Sink (double)',
        'image': 'assets/Sink installation.webp',
        'price': 349.0,
        'unit': 'per sink'
      },
      {
        'name': 'Undermount Sink',
        'image': 'assets/Sink installation.webp',
        'price': 399.0,
        'unit': 'per sink'
      },
    ],
    'Toilet Seat Cover Replacement': [
      {
        'name': 'Standard Seat Cover',
        'image': 'assets/toilet seat cover replacement.webp',
        'price': 159.0,
        'unit': 'per unit'
      },
      {
        'name': 'Soft Close Seat',
        'image': 'assets/toilet seat cover replacement.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
    ],
    'Waste Pipe Replacement': [
      {
        'name': 'Basin Waste Pipe',
        'image': 'assets/waste pipe.webp',
        'price': 199.0,
        'unit': 'per pipe'
      },
      {
        'name': 'Kitchen Waste Pipe',
        'image': 'assets/waste pipe.webp',
        'price': 249.0,
        'unit': 'per pipe'
      },
      {
        'name': 'Bathroom Waste Pipe',
        'image': 'assets/waste pipe.webp',
        'price': 219.0,
        'unit': 'per pipe'
      },
    ],
    'Water Tank Installation': [
      {
        'name': 'Overhead Tank (upto 500L)',
        'image': 'assets/water tank installation.webp',
        'price': 399.0,
        'unit': 'flat'
      },
      {
        'name': 'Overhead Tank (500-1000L)',
        'image': 'assets/water tank installation.webp',
        'price': 549.0,
        'unit': 'flat'
      },
      {
        'name': 'Underground Sump',
        'image': 'assets/water tank installation.webp',
        'price': 699.0,
        'unit': 'flat'
      },
    ],
    'Western Toilet Seat Replacement': [
      {
        'name': 'Standard WC',
        'image': 'assets/westearn.webp',
        'price': 499.0,
        'unit': 'per unit'
      },
      {
        'name': 'Wall-hung WC',
        'image': 'assets/westearn.webp',
        'price': 649.0,
        'unit': 'per unit'
      },
    ],
  },
  'AC Repair': {
    'AC Repair': [
      {
        'name': '1 Ton Split AC',
        'image': 'assets/ac repair.webp',
        'price': 499.0,
        'unit': 'per visit'
      },
      {
        'name': '1.5 Ton Split AC',
        'image': 'assets/ac repair.webp',
        'price': 599.0,
        'unit': 'per visit'
      },
      {
        'name': '2 Ton Split AC',
        'image': 'assets/ac repair.webp',
        'price': 699.0,
        'unit': 'per visit'
      },
      {
        'name': 'Window AC',
        'image': 'assets/ac repair.webp',
        'price': 449.0,
        'unit': 'per visit'
      },
    ],
    'Gas Refill': [
      {
        'name': '1 Ton (R410a)',
        'image': 'assets/gas.webp',
        'price': 1299.0,
        'unit': 'flat'
      },
      {
        'name': '1.5 Ton (R410a)',
        'image': 'assets/gas.webp',
        'price': 1599.0,
        'unit': 'flat'
      },
      {
        'name': '2 Ton (R410a)',
        'image': 'assets/gas.webp',
        'price': 1899.0,
        'unit': 'flat'
      },
      {
        'name': 'Window AC (R22)',
        'image': 'assets/gas.webp',
        'price': 999.0,
        'unit': 'flat'
      },
    ],
    'AC Installation': [
      {
        'name': '1 Ton Split AC',
        'image': 'assets/ac insta.webp',
        'price': 799.0,
        'unit': 'flat'
      },
      {
        'name': '1.5 Ton Split AC',
        'image': 'assets/ac insta.webp',
        'price': 899.0,
        'unit': 'flat'
      },
      {
        'name': '2 Ton Split AC',
        'image': 'assets/ac insta.webp',
        'price': 999.0,
        'unit': 'flat'
      },
      {
        'name': 'Window AC',
        'image': 'assets/ac insta.webp',
        'price': 699.0,
        'unit': 'flat'
      },
    ],
    'Water Leaking': [
      {
        'name': 'Drain Pipe Fix',
        'image': 'assets/water leaking.webp',
        'price': 249.0,
        'unit': 'flat'
      },
      {
        'name': 'Indoor Unit Fix',
        'image': 'assets/water leaking.webp',
        'price': 349.0,
        'unit': 'flat'
      },
      {
        'name': 'Outdoor Unit Fix',
        'image': 'assets/water leaking.webp',
        'price': 299.0,
        'unit': 'flat'
      },
    ],
    'Compressor Change': [
      {
        'name': '1 Ton Compressor',
        'image': 'assets/compressor.webp',
        'price': 3999.0,
        'unit': 'flat'
      },
      {
        'name': '1.5 Ton Compressor',
        'image': 'assets/compressor.webp',
        'price': 4999.0,
        'unit': 'flat'
      },
      {
        'name': '2 Ton Compressor',
        'image': 'assets/compressor.webp',
        'price': 5999.0,
        'unit': 'flat'
      },
    ],
    'AC Moving': [
      {
        'name': 'Same Floor Move',
        'image': 'assets/move.webp',
        'price': 499.0,
        'unit': 'flat'
      },
      {
        'name': 'Different Floor Move',
        'image': 'assets/move.webp',
        'price': 799.0,
        'unit': 'flat'
      },
      {
        'name': 'Dismantle Only',
        'image': 'assets/move.webp',
        'price': 299.0,
        'unit': 'flat'
      },
      {
        'name': 'Reinstall Only',
        'image': 'assets/move.webp',
        'price': 349.0,
        'unit': 'flat'
      },
    ],
  },
  'Carpenter': {
    'BookShelf': [
      {
        'name': 'Small (2-shelf)',
        'image': 'assets/book.webp',
        'price': 599.0,
        'unit': 'per unit'
      },
      {
        'name': 'Medium (4-shelf)',
        'image': 'assets/book.webp',
        'price': 899.0,
        'unit': 'per unit'
      },
      {
        'name': 'Large (6-shelf)',
        'image': 'assets/book.webp',
        'price': 1299.0,
        'unit': 'per unit'
      },
      {
        'name': 'Wall-mounted shelf',
        'image': 'assets/book.webp',
        'price': 399.0,
        'unit': 'per shelf'
      },
    ],
    'Door and Window': [
      {
        'name': 'Interior Door',
        'image': 'assets/window.webp',
        'price': 1499.0,
        'unit': 'per door'
      },
      {
        'name': 'Sliding Door',
        'image': 'assets/window.webp',
        'price': 1999.0,
        'unit': 'per door'
      },
      {
        'name': 'Window Frame',
        'image': 'assets/window.webp',
        'price': 999.0,
        'unit': 'per window'
      },
      {
        'name': 'Door Repair',
        'image': 'assets/window.webp',
        'price': 349.0,
        'unit': 'per door'
      },
      {
        'name': 'Window Repair',
        'image': 'assets/window.webp',
        'price': 299.0,
        'unit': 'per window'
      },
    ],
    'Chair and Table': [
      {
        'name': 'Dining Chair',
        'image': 'assets/chair.webp',
        'price': 899.0,
        'unit': 'per chair'
      },
      {
        'name': 'Study Table',
        'image': 'assets/chair.webp',
        'price': 1499.0,
        'unit': 'per table'
      },
      {
        'name': 'Dining Table (4-seater)',
        'image': 'assets/chair.webp',
        'price': 3999.0,
        'unit': 'per table'
      },
      {
        'name': 'Coffee Table',
        'image': 'assets/chair.webp',
        'price': 1299.0,
        'unit': 'per table'
      },
      {
        'name': 'Chair Repair',
        'image': 'assets/chair.webp',
        'price': 249.0,
        'unit': 'per chair'
      },
    ],
    'Almary': [
      {
        'name': '2-Door Wardrobe',
        'image': 'assets/almary.webp',
        'price': 5999.0,
        'unit': 'per unit'
      },
      {
        'name': '3-Door Wardrobe',
        'image': 'assets/almary.webp',
        'price': 7999.0,
        'unit': 'per unit'
      },
      {
        'name': 'Sliding Wardrobe',
        'image': 'assets/almary.webp',
        'price': 9999.0,
        'unit': 'per unit'
      },
      {
        'name': 'Wardrobe Repair',
        'image': 'assets/almary.webp',
        'price': 399.0,
        'unit': 'per visit'
      },
    ],
    'Bed': [
      {
        'name': 'Single Bed',
        'image': 'assets/bed.webp',
        'price': 4999.0,
        'unit': 'per unit'
      },
      {
        'name': 'Double Bed',
        'image': 'assets/bed.webp',
        'price': 6999.0,
        'unit': 'per unit'
      },
      {
        'name': 'King Size Bed',
        'image': 'assets/bed.webp',
        'price': 8999.0,
        'unit': 'per unit'
      },
      {
        'name': 'Bunk Bed',
        'image': 'assets/bed.webp',
        'price': 7999.0,
        'unit': 'per unit'
      },
      {
        'name': 'Bed Repair',
        'image': 'assets/bed.webp',
        'price': 349.0,
        'unit': 'per visit'
      },
    ],
  },
  'Painter': {
    'Full House': [
      {
        'name': '1 BHK',
        'image': 'assets/whole house.webp',
        'price': 4999.0,
        'unit': 'flat'
      },
      {
        'name': '2 BHK',
        'image': 'assets/whole house.webp',
        'price': 7999.0,
        'unit': 'flat'
      },
      {
        'name': '3 BHK',
        'image': 'assets/whole house.webp',
        'price': 10999.0,
        'unit': 'flat'
      },
      {
        'name': '4 BHK',
        'image': 'assets/whole house.webp',
        'price': 14999.0,
        'unit': 'flat'
      },
    ],
    'One Room': [
      {
        'name': 'Small Room (upto 100 sqft)',
        'image': 'assets/one room.webp',
        'price': 999.0,
        'unit': 'per room'
      },
      {
        'name': 'Medium Room (100-150 sqft)',
        'image': 'assets/one room.webp',
        'price': 1299.0,
        'unit': 'per room'
      },
      {
        'name': 'Large Room (150+ sqft)',
        'image': 'assets/one room.webp',
        'price': 1599.0,
        'unit': 'per room'
      },
      {
        'name': 'Kitchen',
        'image': 'assets/one room.webp',
        'price': 1099.0,
        'unit': 'flat'
      },
      {
        'name': 'Bathroom',
        'image': 'assets/one room.webp',
        'price': 799.0,
        'unit': 'flat'
      },
    ],
    'Window And Door': [
      {
        'name': 'Interior Door (both sides)',
        'image': 'assets/window and door.webp',
        'price': 349.0,
        'unit': 'per door'
      },
      {
        'name': 'Exterior Door',
        'image': 'assets/window and door.webp',
        'price': 449.0,
        'unit': 'per door'
      },
      {
        'name': 'Window (both sides)',
        'image': 'assets/window and door.webp',
        'price': 249.0,
        'unit': 'per window'
      },
      {
        'name': 'Window Frame only',
        'image': 'assets/window and door.webp',
        'price': 149.0,
        'unit': 'per window'
      },
      {
        'name': 'Main Gate',
        'image': 'assets/window and door.webp',
        'price': 599.0,
        'unit': 'flat'
      },
    ],
    'Ceiling Painting': [
      {
        'name': 'Single Room Ceiling',
        'image': 'assets/ceiling paint.webp',
        'price': 799.0,
        'unit': 'per room'
      },
      {
        'name': 'Hall / Living Room',
        'image': 'assets/ceiling paint.webp',
        'price': 1099.0,
        'unit': 'flat'
      },
      {
        'name': 'Full House Ceiling',
        'image': 'assets/ceiling paint.webp',
        'price': 2999.0,
        'unit': 'flat'
      },
      {
        'name': 'POP Work (per sqft)',
        'image': 'assets/ceiling paint.webp',
        'price': 45.0,
        'unit': 'per sqft'
      },
    ],
  },
  'Salon': {
    'Hair Cut': [
      {
        'name': "Men's Hair Cut",
        'image': 'assets/hair.webp',
        'price': 60.0,
        'unit': 'per person'
      },
      {
        'name': "Women's Hair Cut",
        'image': 'assets/hair.webp',
        'price': 100.0,
        'unit': 'per person'
      },
      {
        'name': "Kids Hair Cut",
        'image': 'assets/hair.webp',
        'price': 50.0,
        'unit': 'per person'
      },
      {
        'name': 'Hair Trim',
        'image': 'assets/hair.webp',
        'price': 80.0,
        'unit': 'per person'
      },
      {
        'name': 'Beard Trim',
        'image': 'assets/hair.webp',
        'price': 40.0,
        'unit': 'per person'
      },
      {
        'name': 'Shave',
        'image': 'assets/hair.webp',
        'price': 50.0,
        'unit': 'per person'
      },
    ],
    'Hair Wash': [
      {
        'name': 'Hair Wash (short hair)',
        'image': 'assets/wash.webp',
        'price': 69.0,
        'unit': 'per person'
      },
      {
        'name': 'Hair Wash (long hair)',
        'image': 'assets/wash.webp',
        'price': 99.0,
        'unit': 'per person'
      },
      {
        'name': 'Hair Wash + Conditioning',
        'image': 'assets/wash.webp',
        'price': 129.0,
        'unit': 'per person'
      },
      {
        'name': 'Head Massage + Wash',
        'image': 'assets/wash.webp',
        'price': 149.0,
        'unit': 'per person'
      },
      {
        'name': 'Anti-Dandruff Treatment',
        'image': 'assets/wash.webp',
        'price': 199.0,
        'unit': 'per person'
      },
    ],
    'Makeup': [
      {
        'name': 'Day Makeup',
        'image': 'assets/makeup.webp',
        'price': 299.0,
        'unit': 'per person'
      },
      {
        'name': 'Party Makeup',
        'image': 'assets/makeup.webp',
        'price': 499.0,
        'unit': 'per person'
      },
      {
        'name': 'Bridal Makeup',
        'image': 'assets/makeup.webp',
        'price': 1999.0,
        'unit': 'per person'
      },
      {
        'name': 'Eye Makeup only',
        'image': 'assets/makeup.webp',
        'price': 149.0,
        'unit': 'per person'
      },
      {
        'name': 'Facial',
        'image': 'assets/makeup.webp',
        'price': 349.0,
        'unit': 'per person'
      },
      {
        'name': 'Threading (eyebrows)',
        'image': 'assets/makeup.webp',
        'price': 40.0,
        'unit': 'per person'
      },
      {
        'name': 'Waxing (half legs)',
        'image': 'assets/makeup.webp',
        'price': 199.0,
        'unit': 'per person'
      },
      {
        'name': 'Waxing (full body)',
        'image': 'assets/makeup.webp',
        'price': 799.0,
        'unit': 'per person'
      },
    ],
  },
  'Cleaning': {
    'Home Cleaning': [
      {
        'name': 'Fan',
        'image': 'assets/fan.webp',
        'price': 30.0,
        'unit': 'per fan'
      },
      {
        'name': 'AC',
        'image': 'assets/ac.webp',
        'price': 99.0,
        'unit': 'per AC'
      },
      {
        'name': 'Sofa',
        'image': 'assets/sofa_chair.webp',
        'price': 79.0,
        'unit': 'per sofa'
      },
      {
        'name': 'Window',
        'image': 'assets/windoww.webp',
        'price': 49.0,
        'unit': 'per window'
      },
      {
        'name': 'Door',
        'image': 'assets/door.avif',
        'price': 29.0,
        'unit': 'per door'
      },
      {
        'name': 'Floor (Room)',
        'image': 'assets/floor.webp',
        'price': 99.0,
        'unit': 'per room'
      },
      {
        'name': 'Ceiling',
        'image': 'assets/ceiling.webp',
        'price': 79.0,
        'unit': 'per room'
      },
      {
        'name': 'Wardrobe',
        'image': 'assets/wardrobe.webp',
        'price': 59.0,
        'unit': 'per unit'
      },
      {
        'name': 'Bathroom',
        'image': 'assets/bathroom.webp',
        'price': 99.0,
        'unit': 'per bathroom'
      },
      {
        'name': 'Balcony',
        'image': 'assets/balcony.webp',
        'price': 49.0,
        'unit': 'per balcony'
      },
    ],
    'Kitchen Cleaning': [
      {
        'name': 'Chimney',
        'image': 'assets/chimney.webp',
        'price': 149.0,
        'unit': 'per unit'
      },
      {
        'name': 'Gas Stove',
        'image': 'assets/gas stove.webp',
        'price': 49.0,
        'unit': 'per stove'
      },
      {
        'name': 'Refrigerator',
        'image': 'assets/refrigeratorrr.webp',
        'price': 79.0,
        'unit': 'per unit'
      },
      {
        'name': 'Microwave / Oven',
        'image': 'assets/microwave oven.webp',
        'price': 59.0,
        'unit': 'per unit'
      },
      {
        'name': 'Sink & Counter',
        'image': 'assets/sink and counter.webp',
        'price': 49.0,
        'unit': 'flat'
      },
      {
        'name': 'Kitchen Floor',
        'image': 'assets/kitchen floor.webp',
        'price': 79.0,
        'unit': 'flat'
      },
      {
        'name': 'Cabinet (inside)',
        'image': 'assets/cabinet.webp',
        'price': 39.0,
        'unit': 'per cabinet'
      },
      {
        'name': 'Exhaust Fan',
        'image': 'assets/exhauast fan.webp',
        'price': 30.0,
        'unit': 'per fan'
      },
      {
        'name': 'Tiles & Walls',
        'image': 'assets/tiles and walls.webp',
        'price': 69.0,
        'unit': 'flat'
      },
    ],
    'Bathroom Cleaning': [
      {
        'name': 'Toilet Seat',
        'image': 'assets/toiletseat.webp',
        'price': 49.0,
        'unit': 'per unit'
      },
      {
        'name': 'Shower Area',
        'image': 'assets/shower area.webp',
        'price': 59.0,
        'unit': 'flat'
      },
      {
        'name': 'Basin / Sink',
        'image': 'assets/basin.webp',
        'price': 39.0,
        'unit': 'per unit'
      },
      {
        'name': 'Floor & Tiles',
        'image': 'assets/floor and tiles.webp',
        'price': 69.0,
        'unit': 'flat'
      },
      {
        'name': 'Mirror',
        'image': 'assets/mirror.webp',
        'price': 19.0,
        'unit': 'per mirror'
      },
      {
        'name': 'Geyser',
        'image': 'assets/geyserr.webp',
        'price': 49.0,
        'unit': 'per unit'
      },
      {
        'name': 'Exhaust Fan',
        'image': 'assets/exhauast fan.webp',
        'price': 30.0,
        'unit': 'per fan'
      },
      {
        'name': 'Wall Scrubbing',
        'image': 'assets/wall scrubbing.webp',
        'price': 59.0,
        'unit': 'flat'
      },
    ],
    'Deep Cleaning': [
      {
        'name': 'Bedroom',
        'image': 'assets/bedroom.webp',
        'price': 299.0,
        'unit': 'per room'
      },
      {
        'name': 'Living Room',
        'image': 'assets/living room.webp',
        'price': 349.0,
        'unit': 'flat'
      },
      {
        'name': 'Kitchen',
        'image': 'assets/kitchen.webp',
        'price': 349.0,
        'unit': 'flat'
      },
      {
        'name': 'Bathroom',
        'image': 'assets/bathroom.webp',
        'price': 249.0,
        'unit': 'per unit'
      },
      {
        'name': 'Balcony',
        'image': 'assets/balcony.webp',
        'price': 149.0,
        'unit': 'per balcony'
      },
      {
        'name': 'Sofa',
        'image': 'assets/sofa_chair.webp',
        'price': 199.0,
        'unit': 'per sofa'
      },
      {
        'name': 'Mattress',
        'image': 'assets/mattress.webp',
        'price': 149.0,
        'unit': 'per mattress'
      },
      {
        'name': 'All Windows',
        'image': 'assets/window and door.webp',
        'price': 199.0,
        'unit': 'flat'
      },
    ],
    'Vehicle Cleaning': [
      {
        'name': 'Car (Interior)',
        'image': 'assets/car wash interior.webp',
        'price': 199.0,
        'unit': 'per car'
      },
      {
        'name': 'Car (Exterior)',
        'image': 'assets/car wash exterior.webp',
        'price': 149.0,
        'unit': 'per car'
      },
      {
        'name': 'Bike',
        'image': 'assets/bike wash.webp',
        'price': 79.0,
        'unit': 'per bike'
      },
      {
        'name': 'Auto / Van',
        'image': 'assets/auto.webp',
        'price': 249.0,
        'unit': 'per vehicle'
      },
      {
        'name': 'Engine Wash',
        'image': 'assets/engine wash.webp',
        'price': 149.0,
        'unit': 'per vehicle'
      },
      {
        'name': 'Seat Shampooing',
        'image': 'assets/seat sampooing.webp',
        'price': 99.0,
        'unit': 'per vehicle'
      },
    ],
    'Refrigerator Cleaning': [
      {
        'name': 'Interior Deep Clean',
        'image': 'assets/refrigerator cleaning.webp',
        'price': 99.0,
        'unit': 'flat'
      },
      {
        'name': 'Exterior & Top',
        'image': 'assets/refrigeratorrr.webp',
        'price': 49.0,
        'unit': 'flat'
      },
      {
        'name': 'Coil / Vent Clean',
        'image': 'assets/Refrigerator.webp',
        'price': 79.0,
        'unit': 'flat'
      },
      {
        'name': 'Drip Tray',
        'image': 'assets/refrigeratorrr.webp',
        'price': 29.0,
        'unit': 'flat'
      },
      {
        'name': 'Deodorising',
        'image': 'assets/refrigeratorrr.webp',
        'price': 39.0,
        'unit': 'flat'
      },
    ],
    'Shop Cleaning': [
      {
        'name': 'Floor Mopping',
        'image': 'assets/floor.webp',
        'price': 99.0,
        'unit': 'per 500 sqft'
      },
      {
        'name': 'Glass / Windows',
        'image': 'assets/windoww.webp',
        'price': 69.0,
        'unit': 'per 5 windows'
      },
      {
        'name': 'Shelves / Racks',
        'image': 'assets/classic_wall_shelf.webp',
        'price': 49.0,
        'unit': 'per rack'
      },
      {
        'name': 'Counter / Desk',
        'image': 'assets/sink and counter.webp',
        'price': 39.0,
        'unit': 'per counter'
      },
      {
        'name': 'Ceiling Fan',
        'image': 'assets/fan.webp',
        'price': 30.0,
        'unit': 'per fan'
      },
      {
        'name': 'AC Unit',
        'image': 'assets/ac.webp',
        'price': 99.0,
        'unit': 'per AC'
      },
      {
        'name': 'Washroom',
        'image': 'assets/washroom.webp',
        'price': 99.0,
        'unit': 'per unit'
      },
      {
        'name': 'Entrance / Gate',
        'image': 'assets/entrance gate.webp',
        'price': 29.0,
        'unit': 'flat'
      },
    ],
  },
  'Tailor': {
    'Stitching': [
      {
        'name': 'Simple Kurti',
        'image': 'assets/simple kurti.webp',
        'price': 149.0,
        'unit': 'per piece'
      },
      {
        'name': 'Anarkali Kurti',
        'image': 'assets/anarkali kurti.webp',
        'price': 199.0,
        'unit': 'per piece'
      },
      {
        'name': 'Salwar Kameez',
        'image': 'assets/salwar kameez.webp',
        'price': 249.0,
        'unit': 'per set'
      },
      {
        'name': 'Churidar Suit',
        'image': 'assets/churidar suit.webp',
        'price': 229.0,
        'unit': 'per set'
      },
    ],
    'Blouse Stitching': [
      {
        'name': 'Plain Blouse',
        'image': 'assets/plain blouse.webp',
        'price': 299.0,
        'unit': 'per piece'
      },
      {
        'name': 'Designer Blouse',
        'image': 'assets/designer blouse.webp',
        'price': 499.0,
        'unit': 'per piece'
      },
      {
        'name': 'Halter Neck',
        'image': 'assets/halter neck.webp',
        'price': 399.0,
        'unit': 'per piece'
      },
      {
        'name': 'Deep Back Blouse',
        'image': 'assets/deep back blouse.webp',
        'price': 449.0,
        'unit': 'per piece'
      },
    ],
    'Suit Stitching': [
      {
        'name': 'Formal Suit',
        'image': 'assets/formal suit.webp',
        'price': 999.0,
        'unit': 'per suit'
      },
      {
        'name': 'Sherwani',
        'image': 'assets/sherwani.webp',
        'price': 1499.0,
        'unit': 'per piece'
      },
      {
        'name': 'Bandhgala',
        'image': 'assets/bandhgala.webp',
        'price': 799.0,
        'unit': 'per piece'
      },
      {
        'name': 'Pathani Suit',
        'image': 'assets/pathani suit.webp',
        'price': 699.0,
        'unit': 'per set'
      },
    ],
    'Alteration': [
      {
        'name': 'Shorten / Lengthen',
        'image': 'assets/shorten.webp',
        'price': 99.0,
        'unit': 'per piece'
      },
      {
        'name': 'Waist Adjustment',
        'image': 'assets/waist adjustment.webp',
        'price': 129.0,
        'unit': 'per piece'
      },
      {
        'name': 'Sleeve Alteration',
        'image': 'assets/sleeve alteration.webp',
        'price': 99.0,
        'unit': 'per piece'
      },
      {
        'name': 'Neck Redesign',
        'image': 'assets/neck redesign.webp',
        'price': 149.0,
        'unit': 'per piece'
      },
    ],
    'Kids Dress': [
      {
        'name': 'Frock',
        'image': 'assets/frock.webp',
        'price': 199.0,
        'unit': 'per piece'
      },
      {
        'name': 'Shirt & Pants',
        'image': 'assets/shirt and pants.webp',
        'price': 249.0,
        'unit': 'per set'
      },
      {
        'name': 'School Uniform',
        'image': 'assets/school uniform.webp',
        'price': 299.0,
        'unit': 'per set'
      },
      {
        'name': 'Party Dress',
        'image': 'assets/party dress.webp',
        'price': 349.0,
        'unit': 'per piece'
      },
    ],
    'Bed Sheet': [
      {
        'name': 'Single Bed Sheet',
        'image': 'assets/bedsheet.webp',
        'price': 149.0,
        'unit': 'per sheet'
      },
      {
        'name': 'Double Bed Sheet',
        'image': 'assets/bedsheet.webp',
        'price': 199.0,
        'unit': 'per sheet'
      },
      {
        'name': 'Fitted Bed Sheet',
        'image': 'assets/bedsheet.webp',
        'price': 229.0,
        'unit': 'per sheet'
      },
    ],
    'Female Cloth': [
      {
        'name': 'Simple Kurti',
        'image': 'assets/simple kurti.webp',
        'price': 149.0,
        'unit': 'per piece'
      },
      {
        'name': 'Saree Blouse',
        'image': 'assets/plain blouse.webp',
        'price': 299.0,
        'unit': 'per piece'
      },
      {
        'name': 'Salwar Suit',
        'image': 'assets/salwar kameez.webp',
        'price': 399.0,
        'unit': 'per set'
      },
      {
        'name': 'Lehenga Choli',
        'image': 'assets/femalecloth.webp',
        'price': 699.0,
        'unit': 'per set'
      },
    ],
    'Fitting any type cloth': [
      {
        'name': 'Waist Fitting',
        'image': 'assets/waist adjustment.webp',
        'price': 99.0,
        'unit': 'per piece'
      },
      {
        'name': 'Length Adjustment',
        'image': 'assets/shorten.webp',
        'price': 79.0,
        'unit': 'per piece'
      },
      {
        'name': 'Sleeve Fitting',
        'image': 'assets/sleeve alteration.webp',
        'price': 99.0,
        'unit': 'per piece'
      },
      {
        'name': 'Full Garment Fitting',
        'image': 'assets/fitting_cloth.webp',
        'price': 149.0,
        'unit': 'per piece'
      },
    ],
    'Man Cloth': [
      {
        'name': 'Shirt Stitching',
        'image': 'assets/mancloth.webp',
        'price': 199.0,
        'unit': 'per piece'
      },
      {
        'name': 'Trouser / Pant',
        'image': 'assets/mancloth.webp',
        'price': 149.0,
        'unit': 'per piece'
      },
      {
        'name': 'Kurta Pajama',
        'image': 'assets/mancloth.webp',
        'price': 299.0,
        'unit': 'per set'
      },
      {
        'name': 'Pathani Suit',
        'image': 'assets/pathani suit.webp',
        'price': 499.0,
        'unit': 'per set'
      },
    ],
  },
  'Maid': {
    'Kitchen Maid': [
      {
        'name': '1 Day Service',
        'image': 'assets/kitchen maid.webp',
        'price': 299.0,
        'unit': 'per day'
      },
      {
        'name': '2 Days Service',
        'image': 'assets/kitchen maid.webp',
        'price': 549.0,
        'unit': '2 days'
      },
      {
        'name': 'Monthly Service',
        'image': 'assets/kitchen maid.webp',
        'price': 3999.0,
        'unit': 'per month'
      },
    ],
    'House Maid': [
      {
        'name': '1 Day Service',
        'image': 'assets/house maid.webp',
        'price': 299.0,
        'unit': 'per day'
      },
      {
        'name': '2 Days Service',
        'image': 'assets/house maid.webp',
        'price': 549.0,
        'unit': '2 days'
      },
      {
        'name': 'Monthly Service',
        'image': 'assets/house maid.webp',
        'price': 3999.0,
        'unit': 'per month'
      },
    ],
    'Child Care Maid': [
      {
        'name': '1 Day Service',
        'image': 'assets/child care.webp',
        'price': 299.0,
        'unit': 'per day'
      },
      {
        'name': '2 Days Service',
        'image': 'assets/child care.webp',
        'price': 549.0,
        'unit': '2 days'
      },
      {
        'name': 'Monthly Service',
        'image': 'assets/child care.webp',
        'price': 3999.0,
        'unit': 'per month'
      },
    ],
  },
  'Laundry and Dry Cleaning': {
    'Pressing': [
      {
        'name': 'Shirt',
        'image': 'assets/pressing.webp',
        'price': 15.0,
        'unit': 'per piece'
      },
      {
        'name': 'Trouser',
        'image': 'assets/pressing.webp',
        'price': 15.0,
        'unit': 'per piece'
      },
      {
        'name': 'Saree',
        'image': 'assets/pressing.webp',
        'price': 30.0,
        'unit': 'per piece'
      },
      {
        'name': 'Suit',
        'image': 'assets/pressing.webp',
        'price': 40.0,
        'unit': 'per set'
      },
      {
        'name': 'Bedsheet',
        'image': 'assets/pressing.webp',
        'price': 20.0,
        'unit': 'per piece'
      },
    ],
    'Drying': [
      {
        'name': 'Regular Clothes',
        'image': 'assets/dring.webp',
        'price': 10.0,
        'unit': 'per piece'
      },
      {
        'name': 'Heavy Clothes',
        'image': 'assets/dring.webp',
        'price': 20.0,
        'unit': 'per piece'
      },
      {
        'name': 'Blanket / Quilt',
        'image': 'assets/dring.webp',
        'price': 50.0,
        'unit': 'per piece'
      },
    ],
    'Cleaning': [
      {
        'name': 'Shirt',
        'image': 'assets/cleaningng.webp',
        'price': 20.0,
        'unit': 'per piece'
      },
      {
        'name': 'Trouser',
        'image': 'assets/cleaningng.webp',
        'price': 25.0,
        'unit': 'per piece'
      },
      {
        'name': 'Saree',
        'image': 'assets/cleaningng.webp',
        'price': 50.0,
        'unit': 'per piece'
      },
      {
        'name': 'Suit / Sherwani',
        'image': 'assets/cleaningng.webp',
        'price': 150.0,
        'unit': 'per set'
      },
      {
        'name': 'Blanket / Quilt',
        'image': 'assets/cleaningng.webp',
        'price': 80.0,
        'unit': 'per piece'
      },
      {
        'name': 'Curtain',
        'image': 'assets/cleaningng.webp',
        'price': 60.0,
        'unit': 'per piece'
      },
    ],
  },
};

// Helper to get nested items
List<Map<String, dynamic>> _getNestedItems(
    String categoryName, String subCategoryName) {
  return _kNestedItems[categoryName]?[subCategoryName] ?? [];
}

// ═════════════════════════════════════════════════════════════════
//  SUBCATEGORY SCREEN
// ═════════════════════════════════════════════════════════════════
class SubCategoryScreen extends StatefulWidget {
  final String categoryName;
  final List<Map<String, String>> subList;

  const SubCategoryScreen({
    super.key,
    required this.categoryName,
    required this.subList,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen>
    with SingleTickerProviderStateMixin {
  bool get _isItemBased => _kItemBasedCategories.contains(widget.categoryName);

  // ── Non-item-based local cart (Phone Repairing, Staff) ────────
  final Map<int, int> _localCart = {};

  int get _localTotal => _localCart.values.fold(0, (a, b) => a + b);

  double get _localPrice {
    double t = 0;
    _localCart.forEach((i, q) => t += _resolvePrice(i) * q);
    return t;
  }

  late AnimationController _cartAnim;
  late Animation<Offset> _cartSlide;
  bool _cartVisible = false;

  double _resolvePrice(int idx) {
    final raw = widget.subList[idx]['price'] ?? '';
    final v = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), ''));
    if (v != null && v > 0) return v;
    return kPriceMap[widget.subList[idx]['name'] ?? ''] ?? 0;
  }

  String _itemKey(int index) {
    final sub = widget.subList[index];
    return '${widget.categoryName}||${sub['name']}||${sub['name']}';
  }

  @override
  void initState() {
    super.initState();
    _cartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cartSlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cartAnim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _cartAnim.dispose();
    super.dispose();
  }

  // ─── Availability check ───────────────────────────────────────
  Future<bool> _checkAvailability() async {
    try {
      final aliases = _kCategoryAliases[widget.categoryName] ??
          [widget.categoryName, widget.categoryName.toLowerCase()];

      for (final alias in aliases) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('workers')
              .where('category', arrayContains: alias)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) return true;
        } catch (_) {}
      }

      final fb = await FirebaseFirestore.instance
          .collection('workers')
          .where('isOnline', isEqualTo: true)
          .limit(1)
          .get();
      return fb.docs.isNotEmpty;
    } catch (_) {
      return true;
    }
  }

  void _showNotAvailableDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: _kCyanLight, shape: BoxShape.circle),
                child: const Icon(Icons.location_off_rounded,
                    size: 40, color: _kCyan),
              ),
              const SizedBox(height: 18),
              const Text(
                'Service Not Available 😔',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _kText),
              ),
              const SizedBox(height: 8),
              const Text(
                "We're expanding fast! Coming soon to your area 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(color: _kSubText, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kCyan,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("We'll notify you when available 🔔")),
                    );
                  },
                  child: const Text(
                    'Notify Me',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Item-based: tap opens nested SubItemScreen ───────────────
  void _onItemBasedCardTap(int index) {
    final sub = widget.subList[index];
    final subName = sub['name'] ?? '';
    final nestedItems = _getNestedItems(widget.categoryName, subName);

    if (nestedItems.isNotEmpty) {
      // Open sub-item screen for nested selection
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubItemScreen(
            categoryName: widget.categoryName,
            subCategoryName: subName,
            items: nestedItems,
          ),
        ),
      );
    } else {
      // No nested items → add directly to cart
      _addToGlobalCart(index);
    }
  }

  // ─── Item-based: add/remove from global CartProvider ─────────
  void _addToGlobalCart(int index) {
    HapticFeedback.selectionClick();
    final sub = widget.subList[index];
    context.read<CartProvider>().addItem(
          CartItem(
            category: widget.categoryName,
            subCategory: sub['name'] ?? '',
            name: sub['name'] ?? '',
            image: sub['image'] ?? '',
            price: _resolvePrice(index),
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${sub['name']} added to cart ✓'),
        backgroundColor: _kCyanDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 80),
      ),
    );
  }

  void _removeFromGlobalCart(int index) {
    HapticFeedback.selectionClick();
    context.read<CartProvider>().removeItem(_itemKey(index));
  }

  // ─── Non-item-based: local cart ───────────────────────────────
  Future<void> _checkAndAddLocal(int index) async {
    HapticFeedback.selectionClick();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _kCyan)),
    );

    final ok = await _checkAvailability();
    if (!mounted) return;
    Navigator.pop(context);

    if (!ok) {
      _showNotAvailableDialog();
      return;
    }

    setState(() {
      _localCart[index] = (_localCart[index] ?? 0) + 1;
      if (!_cartVisible) {
        _cartVisible = true;
        _cartAnim.forward();
      }
    });
  }

  void _removeLocal(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if ((_localCart[index] ?? 0) > 0) {
        _localCart[index] = _localCart[index]! - 1;
        if (_localCart[index] == 0) _localCart.remove(index);
      }
      if (_localCart.isEmpty) {
        _cartVisible = false;
        _cartAnim.reverse();
      }
    });
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(cart),
              _buildInfoStrip(),
              _buildGrid(),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: (_isItemBased && !cart.isEmpty) ||
                          (!_isItemBased && _cartVisible)
                      ? 110
                      : 24,
                ),
              ),
            ],
          ),

          // Item-based: global cart bar
          if (_isItemBased) _buildGlobalCartBar(cart),

          // Non-item-based: local cart bar
          if (!_isItemBased)
            SlideTransition(
              position: _cartSlide,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _CartBar(
                  totalItems: _localTotal,
                  totalPrice: _localPrice,
                  onBook: () async {
                    final ok = await _checkAvailability();
                    if (!mounted) return;
                    if (!ok) {
                      _showNotAvailableDialog();
                      return;
                    }
                    final items = <Map<String, dynamic>>[];
                    _localCart.forEach((i, q) {
                      items.add({
                        'name': widget.subList[i]['name']!,
                        'image': widget.subList[i]['image']!,
                        'price': widget.subList[i]['price'] ?? '',
                        'quantity': q,
                      });
                    });
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartScreen(
                          preloadedLocalItems: items,
                          category: widget.categoryName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Global cart bottom bar ───────────────────────────────────
  Widget _buildGlobalCartBar(CartProvider cart) {
    if (cart.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _kCyanDeep,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kCyanDeep.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_rounded,
                          color: Colors.white, size: 20),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Color(0xFFFF5252), shape: BoxShape.circle),
                          child: Text(
                            '${cart.totalCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cart.totalCount} item${cart.totalCount > 1 ? "s" : ""} in cart',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11),
                      ),
                      Text(
                        '₹${cart.totalPrice.toStringAsFixed(0)} total',
                        style: const TextStyle(
                            color: _kCyanMid,
                            fontSize: 15,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kCyan, Color(0xFF26C6DA)]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(color: _kCyan.withOpacity(0.4), blurRadius: 10),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Cart',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sliver AppBar ────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(CartProvider cart) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      stretch: true,
      backgroundColor: _kCyanDark,
      foregroundColor: Colors.white,
      actions: [
        if (_isItemBased && !cart.isEmpty)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Color(0xFFFF5252), shape: BoxShape.circle),
                    child: Text(
                      '${cart.totalCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kCyanDeep, _kCyanDark, _kCyan],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                top: 28,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    '${widget.subList.length} services',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Info strip ───────────────────────────────────────────────
  SliverToBoxAdapter _buildInfoStrip() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: _isItemBased ? const Color(0xFFFFF8E1) : _kCyanLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isItemBased
                ? const Color(0xFFFFD54F).withOpacity(0.7)
                : _kCyanMid.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isItemBased
                  ? Icons.touch_app_rounded
                  : Icons.info_outline_rounded,
              color: _isItemBased ? const Color(0xFFF57F17) : _kCyanDark,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isItemBased
                    ? 'Tap a service to see options · add multiple to cart 🛒'
                    : 'Tap + Add to select · multiple items OK',
                style: TextStyle(
                    color: _isItemBased ? const Color(0xFFF57F17) : _kCyanDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Grid ─────────────────────────────────────────────────────
  SliverPadding _buildGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            if (_isItemBased) {
              return Consumer<CartProvider>(
                builder: (context, cart, _) {
                  final subName = widget.subList[index]['name'] ?? '';
                  final nestedItems =
                      _getNestedItems(widget.categoryName, subName);
                  final hasNested = nestedItems.isNotEmpty;

                  // Count how many nested items are in cart for this subcategory
                  int nestedQtyTotal = 0;
                  if (hasNested) {
                    for (final item in nestedItems) {
                      final key =
                          '${widget.categoryName}||$subName||${item['name']}';
                      nestedQtyTotal += cart.quantityOf(key);
                    }
                  }

                  final directQty = hasNested
                      ? nestedQtyTotal
                      : cart.quantityOf(_itemKey(index));

                  return _ItemCartCard(
                    sub: widget.subList[index],
                    categoryName: widget.categoryName,
                    qty: directQty,
                    resolvedPrice: _resolvePrice(index),
                    hasNested: hasNested,
                    onAdd: () {
                      if (hasNested) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubItemScreen(
                              categoryName: widget.categoryName,
                              subCategoryName: subName,
                              items: nestedItems,
                            ),
                          ),
                        );
                      } else {
                        _addToGlobalCart(index);
                      }
                    },
                    onRemove: hasNested
                        ? () {
                            // Go to SubItemScreen to manage items
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubItemScreen(
                                  categoryName: widget.categoryName,
                                  subCategoryName: subName,
                                  items: nestedItems,
                                ),
                              ),
                            );
                          }
                        : () => _removeFromGlobalCart(index),
                  );
                },
              );
            } else {
              return _ServiceCard(
                sub: widget.subList[index],
                resolvedPrice: _resolvePrice(index),
                qty: _localCart[index] ?? 0,
                onAdd: () => _checkAndAddLocal(index),
                onRemove: () => _removeLocal(index),
              );
            }
          },
          childCount: widget.subList.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  SUB ITEM SCREEN  (items inside a subcategory)
// ═════════════════════════════════════════════════════════════════
class SubItemScreen extends StatelessWidget {
  final String categoryName;
  final String subCategoryName;
  final List<Map<String, dynamic>> items;

  const SubItemScreen({
    super.key,
    required this.categoryName,
    required this.subCategoryName,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: _kCyanDark,
                foregroundColor: Colors.white,
                expandedHeight: 110,
                actions: [
                  if (!cart.isEmpty)
                    IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle),
                              child: Text('${cart.totalCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CartScreen())),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        subCategoryName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kCyanDeep, _kCyanDark, _kCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              // Info strip
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: _kCyanLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kCyanMid.withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.add_shopping_cart_rounded,
                        color: _kCyanDark, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add items · go back to pick more services 🛒',
                        style: TextStyle(
                            color: _kCyanDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
              ),

              // Items grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final item = items[index];
                      final name = item['name'] as String;
                      final price = item['price'] as double;
                      final unit = item['unit'] as String? ?? '';
                      final image = item['image'] as String? ?? '';
                      final itemKey = '$categoryName||$subCategoryName||$name';

                      return Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          final qty = cart.quantityOf(itemKey);
                          return _SubItemCard(
                            name: name,
                            price: price,
                            unit: unit,
                            image: image,
                            qty: qty,
                            onAdd: () {
                              HapticFeedback.selectionClick();
                              context.read<CartProvider>().addItem(
                                    CartItem(
                                      category: categoryName,
                                      subCategory: subCategoryName,
                                      name: name,
                                      image: image,
                                      price: price,
                                    ),
                                  );
                            },
                            onRemove: () {
                              HapticFeedback.selectionClick();
                              context.read<CartProvider>().removeItem(itemKey);
                            },
                          );
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: cart.isEmpty ? 24 : 110),
              ),
            ],
          ),

          // Cart bottom bar
          if (!cart.isEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kCyanDeep,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: _kCyanDeep.withOpacity(0.45),
                            blurRadius: 20,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Stack(clipBehavior: Clip.none, children: [
                          const Icon(Icons.shopping_cart_rounded,
                              color: Colors.white, size: 20),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle),
                              child: Text('${cart.totalCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cart.totalCount} item${cart.totalCount > 1 ? "s" : ""} in cart',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11),
                            ),
                            Text(
                              '₹${cart.totalPrice.toStringAsFixed(0)} total',
                              style: const TextStyle(
                                  color: _kCyanMid,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kCyan, Color(0xFF26C6DA)]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                                color: _kCyan.withOpacity(0.4), blurRadius: 10),
                          ],
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('View Cart',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5)),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 12),
                            ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  SUB ITEM CARD
// ═════════════════════════════════════════════════════════════════
class _SubItemCard extends StatelessWidget {
  final String name;
  final double price;
  final String unit;
  final String image;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _SubItemCard({
    required this.name,
    required this.price,
    required this.unit,
    required this.image,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = qty > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected ? _kCyan : const Color(0xFFDCF0F4),
            width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: selected
                  ? _kCyan.withOpacity(0.18)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.asset(image,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [_kCyanLight, Color(0xFFB2EBF2)])),
                      child: const Center(
                          child: Icon(Icons.home_repair_service_rounded,
                              color: _kCyan, size: 38)),
                    )),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _kCyanDeep, borderRadius: BorderRadius.circular(8)),
              child: Text('₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: _kCyan, borderRadius: BorderRadius.circular(7)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10),
                  const SizedBox(width: 2),
                  Text('×$qty',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
        ]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kText,
                          height: 1.3)),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(unit,
                        style: const TextStyle(fontSize: 10, color: _kSubText)),
                  ],
                ]),
                qty == 0
                    ? _AddButton(onTap: onAdd, color: _kCyan)
                    : _Counter(
                        count: qty,
                        onAdd: onAdd,
                        onRemove: onRemove,
                        color: _kCyan,
                      ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  ITEM CART CARD  (item-based subcategory card)
// ═════════════════════════════════════════════════════════════════
class _ItemCartCard extends StatelessWidget {
  final Map<String, String> sub;
  final String categoryName;
  final int qty;
  final double resolvedPrice;
  final bool hasNested;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ItemCartCard({
    required this.sub,
    required this.categoryName,
    required this.qty,
    required this.resolvedPrice,
    required this.onAdd,
    required this.onRemove,
    this.hasNested = false,
  });

  Color get _accent {
    const Map<String, Color> m = {
      'Electrician': Color(0xFFF57F17),
      'Plumber': Color(0xFF01579B),
      'AC Repair': Color(0xFF006064),
      'Carpenter': Color(0xFF4E342E),
      'Painter': Color(0xFF880E4F),
      'Salon': Color(0xFF4A148C),
      'Cleaning': Color(0xFF0277BD),
      'Tailor': Color(0xFF4A148C),
      'Laundry and Dry Cleaning': Color(0xFF006064),
      'Maid': Color(0xFF1B5E20),
    };
    return m[categoryName] ?? _kCyan;
  }

  @override
  Widget build(BuildContext context) {
    final name = sub['name'] ?? '';
    final image = sub['image'] ?? '';
    final selected = qty > 0;
    final color = _accent;

    return GestureDetector(
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFDCF0F4),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.asset(
                    image,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.15),
                            color.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.home_repair_service_rounded,
                            color: color.withOpacity(0.5), size: 38),
                      ),
                    ),
                  ),
                ),
                // Price badge
                if (resolvedPrice > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: _kCyanDeep,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        hasNested
                            ? 'From ₹${resolvedPrice.toStringAsFixed(0)}'
                            : '₹${resolvedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                // Qty badge
                if (selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(7)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text('×$qty',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                // Arrow badge for nested
                if (hasNested && !selected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: color, size: 10),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kText,
                          height: 1.3),
                    ),
                    qty == 0
                        ? _AddButton(
                            onTap: onAdd,
                            color: color,
                            label: hasNested ? 'Select' : 'Add',
                          )
                        : hasNested
                            ? _EditButton(onTap: onAdd, color: color)
                            : _Counter(
                                count: qty,
                                onAdd: onAdd,
                                onRemove: onRemove,
                                color: color,
                              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
//  SERVICE CARD  (non-item-based)
// ═════════════════════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final Map<String, String> sub;
  final double resolvedPrice;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ServiceCard({
    required this.sub,
    required this.resolvedPrice,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = sub['name'] ?? '';
    final image = sub['image'] ?? '';
    final selected = qty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected ? _kCyan : const Color(0xFFDCF0F4),
            width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: selected
                  ? _kCyan.withOpacity(0.18)
                  : Colors.black.withOpacity(0.05),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(image,
                    height: 108,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          height: 108,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [_kCyanLight, Color(0xFFB2EBF2)]),
                          ),
                          child: const Center(
                              child: Icon(Icons.home_repair_service_rounded,
                                  color: _kCyan, size: 38)),
                        )),
              ),
              if (resolvedPrice > 0)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: _kCyanDeep,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('₹${resolvedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kText,
                          height: 1.3)),
                  const Spacer(),
                  qty == 0
                      ? _AddButton(onTap: onAdd, color: _kCyan)
                      : _Counter(
                          count: qty,
                          onAdd: onAdd,
                          onRemove: onRemove,
                          color: _kCyan,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String label;

  const _AddButton({
    required this.onTap,
    required this.color,
    this.label = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == 'Select'
                  ? Icons.arrow_forward_rounded
                  : Icons.add_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Button (for nested when items already selected) ─────
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _EditButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            Text('Edit',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Counter ─────────────────────────────────────────────────
class _Counter extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Color color;

  const _Counter({
    required this.count,
    required this.onAdd,
    required this.onRemove,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: _kCyanLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kCyanMid.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _CounterBtn(
              icon: Icons.remove_rounded, onTap: onRemove, color: color),
          Expanded(
            child: Center(
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            ),
          ),
          _CounterBtn(icon: Icons.add_rounded, onTap: onAdd, color: color),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CounterBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Cart Bar (non-item-based local cart) ─────────────────────
class _CartBar extends StatelessWidget {
  final int totalItems;
  final double totalPrice;
  final VoidCallback onBook;

  const _CartBar({
    required this.totalItems,
    required this.totalPrice,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: GestureDetector(
        onTap: onBook,
        child: Container(
          decoration: BoxDecoration(
            color: _kCyanDeep,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _kCyanDeep.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.shopping_bag_rounded,
                      color: Colors.white, size: 20),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                          color: _kCyan, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$totalItems',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '$totalItems item${totalItems > 1 ? "s" : ""} selected',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11)),
                    Text(
                        totalPrice > 0
                            ? '₹${totalPrice.toStringAsFixed(0)} total'
                            : 'Ready to book',
                        style: const TextStyle(
                            color: _kCyanMid,
                            fontSize: 15,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_kCyan, Color(0xFF26C6DA)]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: _kCyan.withOpacity(0.4), blurRadius: 10),
                  ],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View Cart',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5)),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 12),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
