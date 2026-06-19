// ignore_for_file: library_private_types_in_public_api
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← ADD (AnnotatedRegion + SystemUiOverlayStyle)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart'; // ← ADD (Consumer, context.read)
import 'cart_provider.dart'; // ← ADD (CartProvider, CartItem)
import 'cart_screen.dart'; // ← ADD (CartScreen)
import 'user_service.dart';
import 'searching_screen.dart';
import 'Payment_screen.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kLightGreen = Color(0xFFEAF5EA);
const _kBg = Color(0xFFF4F6F3);
const _kDark = Color(0xFF1A1A1A);
const double _kPlatformFee = 49;
const double _kGoldPlatformFee = 0;
const double _kGoldDiscountPercent = 10;
const double _kLaundryPricePerSet = 30;
const double _kMaidOneDayPrice = 299;
const double _kMaidTwoDaysPrice = 549;
const double _kMaidMonthlyPrice = 3999;
const double _kWorkerRadiusMetres = 7000;

// ─────────────────────────────────────────────
//  CATEGORY ACCENT COLORS
// ─────────────────────────────────────────────
const Map<String, Color> _kCleaningColors = {
  'Home Cleaning': Color(0xFF0277BD),
  'Kitchen Cleaning': Color(0xFFE65100),
  'Bathroom Cleaning': Color(0xFF00838F),
  'Deep Cleaning': Color(0xFF4527A0),
  'Vehicle Cleaning': Color(0xFF1B5E20),
  'Refrigerator Cleaning': Color(0xFF006064),
  'Shop Cleaning': Color(0xFF4E342E),
  'Water Tank Cleaning': Color(0xFF01579B),
};

const Map<String, Color> _kCategoryColors = {
  'Electrician': Color(0xFFF57F17),
  'Plumber': Color(0xFF01579B),
  'AC Repair': Color(0xFF006064),
  'Carpenter': Color(0xFF4E342E),
  'Painter': Color(0xFF880E4F),
  'Salon': Color(0xFF4A148C),
};

// ─────────────────────────────────────────────
//  ITEM MAPS FOR ALL CATEGORIES
// ─────────────────────────────────────────────

// ── ELECTRICIAN ITEMS ─────────────────────────
const Map<String, List<Map<String, dynamic>>> _kElectricianItems = {
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
};

// ── PLUMBER ITEMS ─────────────────────────────
const Map<String, List<Map<String, dynamic>>> _kPlumberItems = {
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
      'name': 'Overhead Tank (500–1000L)',
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
};

// ── AC REPAIR ITEMS ───────────────────────────
const Map<String, List<Map<String, dynamic>>> _kACRepairItems = {
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
    {
      'name': 'Cassette AC',
      'image': 'assets/ac repair.webp',
      'price': 799.0,
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
};

// ── CARPENTER ITEMS ───────────────────────────
const Map<String, List<Map<String, dynamic>>> _kCarpenterItems = {
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
};

// ── PAINTER ITEMS ─────────────────────────────
const Map<String, List<Map<String, dynamic>>> _kPainterItems = {
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
      'name': 'Medium Room (100–150 sqft)',
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
};

// ── SALON ITEMS ───────────────────────────────
const Map<String, List<Map<String, dynamic>>> _kSalonItems = {
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
};

// ─────────────────────────────────────────────
//  CLEANING ITEMS
// ─────────────────────────────────────────────
const Map<String, Color> _kCleaningItemColors = {
  'Home Cleaning': Color(0xFF0277BD),
  'Kitchen Cleaning': Color(0xFFE65100),
  'Bathroom Cleaning': Color(0xFF00838F),
  'Deep Cleaning': Color(0xFF4527A0),
  'Vehicle Cleaning': Color(0xFF1B5E20),
  'Refrigerator Cleaning': Color(0xFF006064),
  'Shop Cleaning': Color(0xFF4E342E),
  'Water Tank Cleaning': Color(0xFF01579B),
};

const Map<String, List<Map<String, dynamic>>> _kCleaningItems = {
  'Home Cleaning': [
    {
      'name': 'Fan',
      'image': 'assets/fan.webp',
      'price': 30.0,
      'unit': 'per fan'
    },
    {'name': 'AC', 'image': 'assets/ac.webp', 'price': 99.0, 'unit': 'per AC'},
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
  'Water Tank Cleaning': [],
};

// ─────────────────────────────────────────────
//  TANK PRICES
// ─────────────────────────────────────────────
const Map<String, double> _kTankSizePrices = {
  'Up to 500 L': 299,
  '500 – 1000 L': 399,
  '1000 – 2000 L': 549,
  '2000 – 5000 L': 799,
  'Above 5000 L': 999,
};

// ─────────────────────────────────────────────
//  PRICE MAP (fallback)
// ─────────────────────────────────────────────
const Map<String, double> _kPriceMap = {
  'Fan Repair': 199,
  'Fan Installation': 249,
  'Wiring': 299,
  'AC Installation': 200,
  'AC Repair': 2000,
  'Almary Making': 1999,
  'Tap Repair': 149,
  'Pipeline Repair': 249,
  'Home Cleaning': 499,
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
  "Bathroom Cleaning": 399,
  "Kitchen Cleaning": 299,
  "Water Tank Cleaning": 299,
  "Deep Cleaning": 499,
  "Vehicle Cleaning": 199,
  "Refrigerator Cleaning": 149,
  "Shop Cleaning": 209,
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
  "Bed Sheet": 199,
  "Female Cloth": 299,
  "Fitting any type cloth": 100,
  "Man Cloth": 149,
  "Stitching": 149,
  "Blouse Stitching": 299,
  "Kids Dress": 399,
  "Suit Stitching": 399,
  "Alteration": 499,
  "House Maid": 299,
  "Child Care Maid": 299,
  "Kitchen Maid": 299,
};

// ─────────────────────────────────────────────
//  SUB CATEGORIES
// ─────────────────────────────────────────────
const Map<String, List<String>> _kSubCategories = {
  'Plumber': [
    'Tap Repair',
    'Pipeline Repair',
    "Basin Installation",
    "Bathroom Accessories Installation",
    "Flush Tank Installation",
    "Jet Spray Repair",
    "Shower Installation",
    "Shower Repair and Replacement",
    "Sink Installation",
    "Toilet Seat Cover Replacement",
    "Waste Pipe Replacement",
    "Water Tank Installation",
    "Western Toilet Seat Replacement",
    "Flush Tank Repair"
  ],
  'Electrician': [
    'Fan Repair',
    'Fan Installation',
    'Wiring',
    'Light Installation',
    'Switch and Socket Installation',
    'MCB replacement',
    'Tv Installation',
    'Fan Replacement',
    'Switch Replacement',
    'Socket Replacement',
    'Board Installation',
    'Holder Replacement',
    'Wall/Ceiling Light Replacement',
    'Doorbell Replacement',
    'Doorbell Installation',
    'Geyser Installation',
    'Washing Machine Repairing',
    'Refrigerator Repairing',
    'Camera Installation',
    'Refrigerator Gas Filling'
  ],
  'Cleaning': [
    "Home Cleaning",
    "Bathroom Cleaning",
    "Kitchen Cleaning",
    "Water Tank Cleaning",
    "Deep Cleaning",
    "Vehicle Cleaning",
    "Refrigerator Cleaning",
    "Shop Cleaning"
  ],
  'AC Repair': [
    "AC Repair",
    "Gas Refill",
    "AC Installation",
    "Water Leaking",
    "Compressor Change",
    "AC Moving"
  ],
  'Carpenter': [
    'Almary Making',
    "BookShelf",
    "Door and Window",
    "Chair and Table",
    "Almary",
    "Bed"
  ],
  'Maid': ['House Maid', 'Child Care Maid', 'Kitchen Maid'],
  "Phone Repairing": [
    "Screen Changing",
    "Phone Exchange",
    "Full Phone Repairing",
    "Speaker Repairing"
  ],
  "Salon": ["Hair Cut", "Hair Wash", "Makeup"],
  "Painter": ["Full House", "One Room", "Window And Door", "Ceiling Painting"],
  "Laundry and Dry Cleaning": ["Pressing", "Drying", "Cleaning"],
  "Tailor": [
    "Stitching",
    "Blouse Stitching",
    "Suit Stitching",
    "Alteration",
    "Kids Dress",
    "Bed Sheet",
    "Female Cloth",
    "Fitting any type cloth",
    "Man Cloth"
  ],
  "Staff(Boy/Girls)": [
    "Party Boy/Girl",
    "Wedding Boy/Girl",
    "Cafe Staff",
    "Hotel Staff",
    "Shop Staff"
  ],
};

// ─────────────────────────────────────────────
//  PROMO CODES
// ─────────────────────────────────────────────
const Map<String, double> _kPromoCodes = {
  'FIRST50': 50,
  'SAVE20': 20,
  'WELCOME': 30,
};

// ─────────────────────────────────────────────
//  CARPENTER DESIGNS
// ─────────────────────────────────────────────
final Map<String, List<Map<String, String>>> _kCarpenterDesigns = {
  "BookShelf": [
    {
      "name": "Classic Wall Shelf",
      "image": "assets/classic_wall_shelf.webp",
      "desc": "Simple wall-mounted wooden shelf"
    },
    {
      "name": "Modular Bookshelf",
      "image": "assets/modular_bookshelf.webp",
      "desc": "Multi-level modular design"
    },
    {
      "name": "Corner Shelf",
      "image": "assets/corner_shelf.webp",
      "desc": "Space-saving corner unit"
    },
    {
      "name": "Floating Shelf",
      "image": "assets/floating_shelf.webp",
      "desc": "Modern minimalist floating style"
    },
    {
      "name": "Custom Design",
      "image": "assets/book.webp",
      "desc": "Describe your own design"
    },
  ],
  "Door and Window": [
    {
      "name": "Traditional Wood Door",
      "image": "assets/traditional_wood_door.webp",
      "desc": "Classic panelled wooden door"
    },
    {
      "name": "Sliding Door",
      "image": "assets/sliding_door.webp",
      "desc": "Space-saving sliding design"
    },
    {
      "name": "Casement Window",
      "image": "assets/casement_window.webp",
      "desc": "Side-hinged opening window"
    },
    {
      "name": "Bay Window Frame",
      "image": "assets/bay_window.webp",
      "desc": "Projecting window structure"
    },
    {
      "name": "Custom Design",
      "image": "assets/window.webp",
      "desc": "Describe your own design"
    },
  ],
  "Chair and Table": [
    {
      "name": "Dining Table Set",
      "image": "assets/dining_table_set.webp",
      "desc": "4-seater dining table with chairs"
    },
    {
      "name": "Study Table",
      "image": "assets/study_table.webp",
      "desc": "Compact study/work desk"
    },
    {
      "name": "Coffee Table",
      "image": "assets/coffee_table.webp",
      "desc": "Living room center table"
    },
    {
      "name": "Sofa Chair",
      "image": "assets/makingsofa.webp",
      "desc": "Comfortable wooden sofa chair"
    },
    {
      "name": "Custom Design",
      "image": "assets/chair.webp",
      "desc": "Describe your own design"
    },
  ],
  "Almary": [
    {
      "name": "2-Door Wardrobe",
      "image": "assets/2_door_wardrobe.webp",
      "desc": "Standard 2-door wooden wardrobe"
    },
    {
      "name": "3-Door Wardrobe",
      "image": "assets/3_door_wardrobe.webp",
      "desc": "Spacious 3-door with mirror"
    },
    {
      "name": "Sliding Wardrobe",
      "image": "assets/wardrobe.webp",
      "desc": "Modern sliding door wardrobe"
    },
    {
      "name": "Walk-in Closet",
      "image": "assets/almary.webp",
      "desc": "Open walk-in wardrobe system"
    },
    {
      "name": "Custom Design",
      "image": "assets/almary.webp",
      "desc": "Describe your own design"
    },
  ],
  "Bed": [
    {
      "name": "Single Bed",
      "image": "assets/single_bed.webp",
      "desc": "Standard single wooden bed frame"
    },
    {
      "name": "Double Bed",
      "image": "assets/double_bed.webp",
      "desc": "Classic double bed with headboard"
    },
    {
      "name": "King Size Bed",
      "image": "assets/king_size_bed.webp",
      "desc": "Spacious king size bed frame"
    },
    {
      "name": "Storage Bed",
      "image": "assets/strong_bed.webp",
      "desc": "Bed with built-in storage drawers"
    },
    {
      "name": "Custom Design",
      "image": "assets/bed.webp",
      "desc": "Describe your own design"
    },
  ],
  "Almary Making": [
    {
      "name": "2-Door Wardrobe",
      "image": "assets/2_door_wardrobe.webp",
      "desc": "Standard 2-door wooden wardrobe"
    },
    {
      "name": "3-Door Wardrobe",
      "image": "assets/3_door_wardrobe.webp",
      "desc": "Spacious 3-door with mirror"
    },
    {
      "name": "Custom Design",
      "image": "assets/almary.webp",
      "desc": "Describe your own design"
    },
  ],
};

// ─────────────────────────────────────────────
//  TAILOR DESIGNS
// ─────────────────────────────────────────────
final Map<String, List<Map<String, String>>> _kTailorDesigns = {
  "Stitching": [
    {
      "name": "Simple Kurti",
      "image": "assets/simple kurti.webp",
      "desc": "Straight-cut casual kurti"
    },
    {
      "name": "Anarkali Kurti",
      "image": "assets/anarkali kurti.webp",
      "desc": "Flared anarkali style"
    },
    {
      "name": "Salwar Kameez",
      "image": "assets/salwar kameez.webp",
      "desc": "Traditional salwar kameez set"
    },
    {
      "name": "Churidar Suit",
      "image": "assets/churidar suit.webp",
      "desc": "Fitted churidar with kameez"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Blouse Stitching": [
    {
      "name": "Plain Blouse",
      "image": "assets/plain blouse.webp",
      "desc": "Simple back-hook blouse"
    },
    {
      "name": "Designer Blouse",
      "image": "assets/designer blouse.webp",
      "desc": "Embroidered or patch work"
    },
    {
      "name": "Halter Neck",
      "image": "assets/halter neck.webp",
      "desc": "Trendy halter neck blouse"
    },
    {
      "name": "Deep Back Blouse",
      "image": "assets/deep back blouse.webp",
      "desc": "Deep-back designer style"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Suit Stitching": [
    {
      "name": "Formal Suit",
      "image": "assets/formal suit.webp",
      "desc": "Classic formal 2-piece suit"
    },
    {
      "name": "Sherwani",
      "image": "assets/sherwani.webp",
      "desc": "Traditional wedding sherwani"
    },
    {
      "name": "Bandhgala",
      "image": "assets/bandhgala.webp",
      "desc": "Nehru collar bandhgala jacket"
    },
    {
      "name": "Pathani Suit",
      "image": "assets/pathani suit.webp",
      "desc": "Traditional pathani kurta set"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Alteration": [
    {
      "name": "Shorten / Lengthen",
      "image": "assets/shorten.webp",
      "desc": "Adjust length of garment"
    },
    {
      "name": "Waist Adjustment",
      "image": "assets/waist adjustment.webp",
      "desc": "Take in or let out the waist"
    },
    {
      "name": "Sleeve Alteration",
      "image": "assets/sleeve alteration.webp",
      "desc": "Change sleeve length or style"
    },
    {
      "name": "Neck Redesign",
      "image": "assets/neck redesign.webp",
      "desc": "Modify neckline shape"
    },
    {
      "name": "Custom Alteration",
      "image": "assets/tailor.webp",
      "desc": "Describe what you need changed"
    },
  ],
  "Kids Dress": [
    {
      "name": "Frock",
      "image": "assets/frock.webp",
      "desc": "Cute kids frock design"
    },
    {
      "name": "Shirt & Pants",
      "image": "assets/shirt and pants.webp",
      "desc": "Casual kids shirt & trousers"
    },
    {
      "name": "School Uniform",
      "image": "assets/school uniform.webp",
      "desc": "Standard school uniform set"
    },
    {
      "name": "Party Dress",
      "image": "assets/party dress.webp",
      "desc": "Fancy party wear for kids"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Bed Sheet": [
    {
      "name": "Single Bed Sheet",
      "image": "assets/bedsheet.webp",
      "desc": "Single size bed sheet stitching"
    },
    {
      "name": "Double Bed Sheet",
      "image": "assets/bedsheet.webp",
      "desc": "Double size bed sheet stitching"
    },
    {
      "name": "Fitted Bed Sheet",
      "image": "assets/bedsheet.webp",
      "desc": "Elastic corner fitted sheet"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Female Cloth": [
    {
      "name": "Simple Kurti",
      "image": "assets/simple kurti.webp",
      "desc": "Casual everyday kurti"
    },
    {
      "name": "Saree Blouse",
      "image": "assets/plain blouse.webp",
      "desc": "Fitted saree blouse"
    },
    {
      "name": "Salwar Suit",
      "image": "assets/salwar kameez.webp",
      "desc": "Full salwar suit set"
    },
    {
      "name": "Lehenga Choli",
      "image": "assets/femalecloth.webp",
      "desc": "Festive lehenga choli"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
  "Fitting any type cloth": [
    {
      "name": "Waist Fitting",
      "image": "assets/waist adjustment.webp",
      "desc": "Adjust waist to perfect fit"
    },
    {
      "name": "Length Adjustment",
      "image": "assets/shorten.webp",
      "desc": "Shorten or lengthen garment"
    },
    {
      "name": "Sleeve Fitting",
      "image": "assets/sleeve alteration.webp",
      "desc": "Adjust sleeve fit & length"
    },
    {
      "name": "Full Garment Fitting",
      "image": "assets/fitting_cloth.webp",
      "desc": "Complete resizing of garment"
    },
    {
      "name": "Custom Fitting",
      "image": "assets/tailor.webp",
      "desc": "Describe what needs fitting"
    },
  ],
  "Man Cloth": [
    {
      "name": "Shirt Stitching",
      "image": "assets/mancloth.webp",
      "desc": "Casual or formal shirt"
    },
    {
      "name": "Trouser / Pant",
      "image": "assets/mancloth.webp",
      "desc": "Formal or casual trousers"
    },
    {
      "name": "Kurta Pajama",
      "image": "assets/mancloth.webp",
      "desc": "Traditional kurta pajama set"
    },
    {
      "name": "Pathani Suit",
      "image": "assets/pathani suit.webp",
      "desc": "Classic pathani suit"
    },
    {
      "name": "Custom Design",
      "image": "assets/tailor.webp",
      "desc": "Describe your own style"
    },
  ],
};

// ─────────────────────────────────────────────
//  CLOUDINARY
// ─────────────────────────────────────────────
final _cloudinary =
    CloudinaryPublic('doeswlkl3', 'worker_upload', cache: false);

// ═══════════════════════════════════════════════════════════════════════════
//  BOOK SERVICE SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class BookServiceScreen extends StatefulWidget {
  final String category;
  final String subCategory;
  final String? serviceName;
  final List<Map<String, dynamic>>? selectedItems;

  const BookServiceScreen({
    super.key,
    required this.category,
    required this.subCategory,
    this.serviceName,
    this.selectedItems,
  });

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────
  late String _selectedService;
  String? _selectedSubCategory;
  String? _selectedTankSize;
  String? _selectedCarpenterDesign;
  final _carpenterCustomDescCtrl = TextEditingController();
  int _clothSets = 1;
  String _maidDuration = '1 Day';
  String? _selectedTailorDesign;
  final _tailorCustomDescCtrl = TextEditingController();
  final _tailorClothDescCtrl = TextEditingController();
  File? _tailorClothImage;

  final Map<String, int> _genericItemQty = {};
  final Map<String, int> _cleaningItemQty = {};

  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  File? _selectedImage;

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _isGoldMember = false;
  bool _isCheckingGold = true;
  String _paymentMethod = 'COD';
  double _basePrice = 0;
  double _promoDiscount = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── getters ────────────────────────────────────────────────────────────
  bool get _isCartMode =>
      widget.selectedItems != null && widget.selectedItems!.isNotEmpty;

  bool get _isSubCategoryPreSelected {
    if (_isCartMode) return false;
    if (widget.subCategory.isEmpty) return false;
    final subs = _kSubCategories[widget.category] ?? [];
    return subs.contains(widget.subCategory);
  }

  String get _effectiveSub => _selectedSubCategory ?? widget.subCategory;
  bool get _isTankCleaning => _effectiveSub == 'Water Tank Cleaning';
  bool get _isCleaning => _selectedService == 'Cleaning';
  bool get _isCarpenter => _selectedService == 'Carpenter';
  bool get _isLaundry => _selectedService == 'Laundry and Dry Cleaning';
  bool get _isTailor => _selectedService == 'Tailor';
  bool get _isMaid => _selectedService == 'Maid';
  bool get _isElectrician => _selectedService == 'Electrician';
  bool get _isPlumber => _selectedService == 'Plumber';
  bool get _isACRepair => _selectedService == 'AC Repair';
  bool get _isPainter => _selectedService == 'Painter';
  bool get _isSalon => _selectedService == 'Salon';

  bool get _isItemBasedCleaning =>
      _isCleaning &&
      !_isTankCleaning &&
      (_kCleaningItems[_effectiveSub]?.isNotEmpty ?? false);

  List<Map<String, dynamic>> get _currentGenericItems {
    if (_isElectrician) return _kElectricianItems[_effectiveSub] ?? [];
    if (_isPlumber) return _kPlumberItems[_effectiveSub] ?? [];
    if (_isACRepair) return _kACRepairItems[_effectiveSub] ?? [];
    if (_isCarpenter) return _kCarpenterItems[_effectiveSub] ?? [];
    if (_isPainter) return _kPainterItems[_effectiveSub] ?? [];
    if (_isSalon) return _kSalonItems[_effectiveSub] ?? [];
    return [];
  }

  bool get _isGenericItemBased => _currentGenericItems.isNotEmpty;

  bool get _isTailorWithDesign {
    const d = {
      "Stitching",
      "Blouse Stitching",
      "Suit Stitching",
      "Alteration",
      "Kids Dress",
      "Bed Sheet",
      "Female Cloth",
      "Fitting any type cloth",
      "Man Cloth"
    };
    return _isTailor && d.contains(_effectiveSub);
  }

  double get _effectivePlatformFee =>
      _isGoldMember ? _kGoldPlatformFee : _kPlatformFee;
  double get _goldDiscount => _isGoldMember
      ? (_basePrice * _kGoldDiscountPercent / 100).roundToDouble()
      : 0;
  double get _total =>
      _basePrice + _effectivePlatformFee - _promoDiscount - _goldDiscount;

  double get _maidPrice {
    switch (_maidDuration) {
      case '2 Days':
        return _kMaidTwoDaysPrice;
      case 'Monthly':
        return _kMaidMonthlyPrice;
      default:
        return _kMaidOneDayPrice;
    }
  }

  double get _cleaningItemsTotal {
    if (!_isItemBasedCleaning) return 0;
    double sum = 0;
    for (final item in _kCleaningItems[_effectiveSub] ?? []) {
      sum += (_cleaningItemQty[item['name'] as String] ?? 0) *
          (item['price'] as double);
    }
    return sum;
  }

  int get _cleaningItemCount {
    int c = 0;
    _cleaningItemQty.forEach((_, q) {
      if (q > 0) c++;
    });
    return c;
  }

  double get _genericItemsTotal {
    double sum = 0;
    for (final item in _currentGenericItems) {
      sum += (_genericItemQty[item['name'] as String] ?? 0) *
          (item['price'] as double);
    }
    return sum;
  }

  int get _genericItemCount {
    int c = 0;
    _genericItemQty.forEach((_, q) {
      if (q > 0) c++;
    });
    return c;
  }

  Color get _accentColor {
    if (_isElectrician) return _kCategoryColors['Electrician']!;
    if (_isPlumber) return _kCategoryColors['Plumber']!;
    if (_isACRepair) return _kCategoryColors['AC Repair']!;
    if (_isCarpenter) return _kCategoryColors['Carpenter']!;
    if (_isPainter) return _kCategoryColors['Painter']!;
    if (_isSalon) return _kCategoryColors['Salon']!;
    if (_isItemBasedCleaning)
      return _kCleaningColors[_effectiveSub] ?? Colors.cyan;
    return Colors.cyan;
  }

  // ── lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedService = widget.category;
    _selectedSubCategory =
        widget.subCategory.isNotEmpty ? widget.subCategory : null;
    _updatePrice();
    _getCurrentLocation();
    _checkGoldStatus();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _locCtrl.dispose();
    _promoCtrl.dispose();
    _carpenterCustomDescCtrl.dispose();
    _tailorCustomDescCtrl.dispose();
    _tailorClothDescCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkGoldStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isCheckingGold = false);
      return;
    }
    try {
      final isGold = await UserService().isGoldMember(uid);
      if (mounted)
        setState(() {
          _isGoldMember = isGold;
          _isCheckingGold = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isCheckingGold = false);
    }
  }

  void _updatePrice() {
    setState(() {
      if (_isCartMode) {
        _basePrice = widget.selectedItems!.fold(
            0.0,
            (s, item) =>
                s +
                (_kPriceMap[item["name"] as String] ?? 199) *
                    (item["quantity"] as int));
      } else if (_isLaundry) {
        _basePrice = _kLaundryPricePerSet * _clothSets;
      } else if (_isMaid) {
        _basePrice = _maidPrice;
      } else if (_isTankCleaning && _selectedTankSize != null) {
        _basePrice = _kTankSizePrices[_selectedTankSize!] ?? 299;
      } else if (_isItemBasedCleaning) {
        _basePrice = _cleaningItemsTotal;
      } else if (_isGenericItemBased) {
        _basePrice = _genericItemsTotal;
      } else {
        _basePrice = _kPriceMap[_effectiveSub] ?? 199;
      }
      _promoDiscount = 0;
      _promoCtrl.clear();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        if (mounted) _showSnack('Location permission denied.', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _locCtrl.text =
            '${p.subLocality ?? ''}, ${p.locality}, ${p.administrativeArea}'
                .replaceAll(RegExp(r'^,\s*'), '');
      }
    } catch (_) {
      if (mounted) _showSnack('Could not fetch location.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<bool> _hasNearbyWorkers(
      {required String category,
      required double userLat,
      required double userLng}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workers')
          .where('isOnline', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final wLat = data['lat'] as double?;
        final wLng = data['lng'] as double?;
        if (wLat == null || wLng == null) continue;
        if (!(data['category'] as List? ?? []).contains(category)) continue;
        if (Geolocator.distanceBetween(userLat, userLng, wLat, wLng) <=
            _kWorkerRadiusMetres) return true;
      }
    } catch (e) {
      debugPrint('Worker check error: $e');
      return true;
    }
    return false;
  }

  void _showNotAvailableDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFFFB74D), width: 2)),
                child: const Icon(Icons.location_off_rounded,
                    color: Color(0xFFFF8F00), size: 40)),
            const SizedBox(height: 20),
            const Text('Service Not Available',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
                'Sorry, no $_selectedService workers are available near you right now.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E4DF)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Go Back',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveNotifyMeRequest();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Notify Me',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _saveNotifyMeRequest() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('notify_requests').add({
        'userId': uid,
        'category': _selectedService,
        'subCategory': _effectiveSub,
        'location': _locCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _showSnack('We\'ll notify you when service is available 🔔');
    } catch (_) {}
  }

  void _showImageOptions({bool isTailor = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(isTailor ? 'Upload Cloth Photo' : 'Add Photo',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _imgOption(Icons.camera_alt_rounded, 'Camera',
                () => _pickImage(ImageSource.camera, isTailor: isTailor)),
            _imgOption(Icons.photo_library_rounded, 'Gallery',
                () => _pickImage(ImageSource.gallery, isTailor: isTailor)),
          ]),
          const SizedBox(height: 10),
        ]),
      )),
    );
  }

  Widget _imgOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Column(children: [
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: _kLightGreen, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.cyan, size: 28)),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]));
  }

  Future<void> _pickImage(ImageSource source, {bool isTailor = false}) async {
    final img = await ImagePicker()
        .pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    if (img != null && mounted) {
      setState(() {
        if (isTailor)
          _tailorClothImage = File(img.path);
        else
          _selectedImage = File(img.path);
      });
    }
  }

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    final disc = _kPromoCodes[code] ?? 0;
    setState(() => _promoDiscount = disc);
    disc > 0
        ? _showSnack('Promo applied! You saved ₹${disc.toStringAsFixed(0)} 🎉')
        : _showSnack('Invalid or expired promo code.', isError: true);
  }

  Future<String?> _uploadImage({File? file}) async {
    final target = file ?? _selectedImage;
    if (target == null) return null;
    try {
      final res = await _cloudinary.uploadFile(CloudinaryFile.fromFile(
          target.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'booking_images'));
      return res.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary error: $e');
      return null;
    }
  }

  Future<void> _notifyNearbyWorkers(
      {required String category,
      required double userLat,
      required double userLng}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workers')
          .where('isOnline', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final wLat = data['lat'] as double?;
        final wLng = data['lng'] as double?;
        if (wLat == null || wLng == null) continue;
        if (!(data['category'] as List? ?? []).contains(category)) continue;
        if (Geolocator.distanceBetween(userLat, userLng, wLat, wLng) >
            _kWorkerRadiusMetres) continue;
        final token = data['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'token': token,
            'title': 'New Job Request',
            'body': 'A $category booking is available near you',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Notify workers error: $e');
    }
  }

  bool _validate() {
    if (!_isCartMode &&
        !_isSubCategoryPreSelected &&
        _selectedSubCategory == null) {
      _showSnack('Please select a service type.', isError: true);
      return false;
    }
    if (_isTankCleaning && _selectedTankSize == null) {
      _showSnack('Please select your tank size.', isError: true);
      return false;
    }
    if (_isItemBasedCleaning && _cleaningItemCount == 0) {
      _showSnack('Please select at least one item to clean.', isError: true);
      return false;
    }
    if (_isGenericItemBased && _genericItemCount == 0) {
      _showSnack('Please select at least one item.', isError: true);
      return false;
    }
    if (_isCarpenter && _selectedCarpenterDesign == null) {
      _showSnack('Please select a design style.', isError: true);
      return false;
    }
    if (_isCarpenter &&
        _selectedCarpenterDesign == 'Custom Design' &&
        _carpenterCustomDescCtrl.text.trim().isEmpty) {
      _showSnack('Please describe your custom design.', isError: true);
      return false;
    }
    if (_isLaundry && _clothSets < 1) {
      _showSnack('Please add at least 1 set of clothes.', isError: true);
      return false;
    }
    if (_isTailorWithDesign && _selectedTailorDesign == null) {
      _showSnack('Please select a design style.', isError: true);
      return false;
    }
    if (_isTailorWithDesign &&
        (_selectedTailorDesign == 'Custom Design' ||
            _selectedTailorDesign == 'Custom Alteration' ||
            _selectedTailorDesign == 'Custom Fitting') &&
        _tailorCustomDescCtrl.text.trim().isEmpty) {
      _showSnack('Please describe your design.', isError: true);
      return false;
    }
    if (_isTailorWithDesign && _tailorClothDescCtrl.text.trim().isEmpty) {
      _showSnack('Please describe your cloth / fabric.', isError: true);
      return false;
    }
    if (_locCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your location.', isError: true);
      return false;
    }
    if (!_isCarpenter &&
        !_isLaundry &&
        !_isTailorWithDesign &&
        !_isMaid &&
        !_isItemBasedCleaning &&
        !_isTankCleaning &&
        !_isGenericItemBased &&
        _descCtrl.text.trim().isEmpty) {
      _showSnack('Please describe the issue.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _sendRequest() async {
    if (!_validate()) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnack('Please login first', isError: true);
      return;
    }
    setState(() => _isLoading = true);

    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      if (mounted) _showSnack('Enable location services', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final available = await _hasNearbyWorkers(
        category: _selectedService,
        userLat: pos.latitude,
        userLng: pos.longitude);
    if (!available) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotAvailableDialog();
      }
      return;
    }

    if (_paymentMethod == 'ONLINE') {
      setState(() => _isLoading = false);
      final paid = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => PaymentsScreen(
                  amount: _total,
                  serviceName: '${widget.category} · $_effectiveSub')));
      if (paid != true) return;
      setState(() => _isLoading = true);
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl;
      String? tailorClothImageUrl;
      try {
        imageUrl = await _uploadImage();
        if (_isTailorWithDesign && _tailorClothImage != null)
          tailorClothImageUrl = await _uploadImage(file: _tailorClothImage);
      } catch (e) {
        debugPrint('Image upload failed: $e');
      }

      Map<String, dynamic> cleaningItemsMap = {};
      String cleaningItemsSummary = '';
      if (_isItemBasedCleaning) {
        final items = _kCleaningItems[_effectiveSub] ?? [];
        final selected = <String>[];
        for (final item in items) {
          final qty = _cleaningItemQty[item['name'] as String] ?? 0;
          if (qty > 0) {
            selected.add('${item['name']} ×$qty');
            cleaningItemsMap[item['name'] as String] = qty;
          }
        }
        cleaningItemsSummary = selected.join(', ');
      }

      Map<String, dynamic> genericItemsMap = {};
      String genericItemsSummary = '';
      if (_isGenericItemBased) {
        final selected = <String>[];
        for (final item in _currentGenericItems) {
          final qty = _genericItemQty[item['name'] as String] ?? 0;
          if (qty > 0) {
            selected.add('${item['name']} ×$qty');
            genericItemsMap[item['name'] as String] = qty;
          }
        }
        genericItemsSummary = selected.join(', ');
      }

      final subCatLabel = _isCartMode
          ? widget.selectedItems!
              .map((e) => '${e["name"]} x${e["quantity"]}')
              .join(', ')
          : _effectiveSub;

      final carpenterNote = _isCarpenter
          ? (_selectedCarpenterDesign == 'Custom Design'
              ? 'Custom: ${_carpenterCustomDescCtrl.text.trim()}'
              : _selectedCarpenterDesign ?? '')
          : '';
      final tailorNote = _isTailorWithDesign
          ? (_selectedTailorDesign == 'Custom Design' ||
                  _selectedTailorDesign == 'Custom Alteration' ||
                  _selectedTailorDesign == 'Custom Fitting'
              ? 'Custom: ${_tailorCustomDescCtrl.text.trim()}'
              : _selectedTailorDesign ?? '')
          : '';

      String description = '';
      if (_isCarpenter)
        description = 'Design: $carpenterNote';
      else if (_isLaundry)
        description = 'Cloth sets: $_clothSets';
      else if (_isTailorWithDesign)
        description =
            'Design: $tailorNote | Cloth: ${_tailorClothDescCtrl.text.trim()}';
      else if (_isMaid)
        description = 'Duration: $_maidDuration';
      else if (_isItemBasedCleaning)
        description = 'Items: $cleaningItemsSummary';
      else if (_isGenericItemBased)
        description = 'Items: $genericItemsSummary';
      else
        description = _descCtrl.text.trim();

      final docRef =
          await FirebaseFirestore.instance.collection('requests').add({
        'userId': uid,
        'category': _selectedService,
        'subCategory': subCatLabel,
        'service': _selectedService,
        'location': _locCtrl.text.trim(),
        'description': description,
        'status': 'pending',
        'workerId': null,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'imageUrl': imageUrl,
        'isScheduled': false,
        'basePrice': _basePrice,
        'platformFee': _effectivePlatformFee,
        'promoDiscount': _promoDiscount,
        'goldDiscount': _goldDiscount,
        'total': _total,
        'paymentMethod': _paymentMethod,
        'isPaid': _paymentMethod == 'ONLINE',
        'isGoldBooking': _isGoldMember,
        'cartItems': _isCartMode ? widget.selectedItems : null,
        if (_isTankCleaning && _selectedTankSize != null)
          'tankSize': _selectedTankSize,
        if (_isCarpenter) 'carpenterDesign': carpenterNote,
        if (_isLaundry) 'clothSets': _clothSets,
        if (_isMaid) 'maidDuration': _maidDuration,
        if (_isItemBasedCleaning && cleaningItemsMap.isNotEmpty)
          'cleaningItems': cleaningItemsMap,
        if (_isGenericItemBased && genericItemsMap.isNotEmpty)
          'serviceItems': genericItemsMap,
        if (_isTailorWithDesign) ...{
          'tailorDesign': tailorNote,
          'tailorClothDesc': _tailorClothDescCtrl.text.trim(),
          if (tailorClothImageUrl != null)
            'tailorClothImageUrl': tailorClothImageUrl,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _notifyNearbyWorkers(
          category: _selectedService,
          userLat: pos.latitude,
          userLng: pos.longitude);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SearchingScreen(requestId: docRef.id)));
    } catch (e) {
      debugPrint('Send request error: $e');
      if (mounted)
        _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.cyan,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: Consumer<CartProvider>(
          builder: (context, cart, _) {
            if (cart.isEmpty) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              backgroundColor: const Color(0xFF0097A7),
              elevation: 6,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: Colors.white, size: 22),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cart.totalCount > 9 ? '9+' : '${cart.totalCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: Text(
                '₹${cart.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
        body: Column(children: [
          _buildTopHeader(),
          if (_isGoldMember) _buildGoldBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isCartMode ? _buildCartSummary() : _buildServiceHero(),
                    const SizedBox(height: 12),
                    if (!_isCartMode && !_isSubCategoryPreSelected) ...[
                      _buildServiceSelector(),
                      const SizedBox(height: 12),
                    ],
                    if (_isTankCleaning && !_isCartMode) ...[
                      _buildTankSizeCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isItemBasedCleaning && !_isCartMode) ...[
                      _buildCleaningItemsCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isGenericItemBased && !_isCartMode) ...[
                      _buildGenericItemsCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isCarpenter &&
                        !_isCartMode &&
                        !_isGenericItemBased) ...[
                      _buildCarpenterDesignCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isLaundry && !_isCartMode) ...[
                      _buildLaundryClothCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isMaid && !_isCartMode) ...[
                      _buildMaidDurationCard(),
                      const SizedBox(height: 12),
                    ],
                    if (_isTailorWithDesign && !_isCartMode) ...[
                      _buildTailorDesignCard(),
                      const SizedBox(height: 12),
                    ],
                    _buildLocationCard(),
                    const SizedBox(height: 12),
                    if (!_isCarpenter &&
                        !_isLaundry &&
                        !_isTailorWithDesign &&
                        !_isMaid &&
                        !_isItemBasedCleaning &&
                        !_isTankCleaning &&
                        !_isGenericItemBased) ...[
                      _buildIssueDetailsCard(),
                      const SizedBox(height: 12),
                    ],
                    _buildPromoCard(),
                    const SizedBox(height: 12),
                    _buildBillCard(),
                    const SizedBox(height: 12),
                    _buildPaymentCard(),
                    const SizedBox(height: 90),
                  ]),
            ),
          ),
          _buildConfirmBar(),
        ]),
      ),
    );
  }

  // ── TOP HEADER ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    final color = _accentColor;
    return Container(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _effectiveSub.isNotEmpty
                          ? _effectiveSub
                          : widget.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isGoldMember)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.workspace_premium,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('GOLD',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── gold banner ────────────────────────────────────────────────────────
  Widget _buildGoldBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)),
      child: Row(children: [
        const Icon(Icons.workspace_premium, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                '⭐ Gold Member: Free platform fee + ${_kGoldDiscountPercent.toInt()}% off service charge applied!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
        Text('Save ₹${(_goldDiscount + _kPlatformFee).toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ]),
    );
  }

  // ── service hero ───────────────────────────────────────────────────────
  Widget _buildServiceHero() {
    final color1 = _accentColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color1, color1.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(_serviceIcon, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.category,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(_effectiveSub,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          if (_isLaundry)
            Text(
                '$_clothSets set${_clothSets > 1 ? 's' : ''} × ₹${_kLaundryPricePerSet.toInt()}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (_isMaid)
            Text('Duration: $_maidDuration',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (_isGenericItemBased && _genericItemCount > 0)
            Text(
                '$_genericItemCount item${_genericItemCount > 1 ? 's' : ''} selected',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (_isItemBasedCleaning && _cleaningItemCount > 0)
            Text(
                '$_cleaningItemCount item${_cleaningItemCount > 1 ? 's' : ''} selected',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (_isTankCleaning && _selectedTankSize != null)
            Text('Tank: $_selectedTankSize',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Text(
              _isGenericItemBased && _genericItemCount == 0
                  ? 'Add items'
                  : _isTankCleaning && _selectedTankSize == null
                      ? 'Select size'
                      : _isItemBasedCleaning && _cleaningItemCount == 0
                          ? 'Add items'
                          : '₹${_basePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ]),
    );
  }

  IconData get _serviceIcon {
    if (_isElectrician) return Icons.electrical_services_rounded;
    if (_isPlumber) return Icons.plumbing_rounded;
    if (_isACRepair) return Icons.ac_unit_rounded;
    if (_isCarpenter) return Icons.carpenter;
    if (_isPainter) return Icons.format_paint_rounded;
    if (_isSalon) return Icons.content_cut_rounded;
    if (_isLaundry) return Icons.local_laundry_service_rounded;
    if (_isTailor) return Icons.content_cut_rounded;
    if (_isMaid) return Icons.cleaning_services_rounded;
    if (_isCleaning) return Icons.cleaning_services_rounded;
    return Icons.home_repair_service_rounded;
  }

  // ── cart summary ───────────────────────────────────────────────────────
  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECE7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shopping_cart_rounded,
                  color: Colors.cyan, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.category,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
            Text(
                '${widget.selectedItems!.length} service${widget.selectedItems!.length > 1 ? 's' : ''} selected',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 12),
        ...widget.selectedItems!.map((item) {
          final name = item["name"] as String;
          final qty = item["quantity"] as int;
          final price = _kPriceMap[name] ?? 199;
          return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                        child: Text('x$qty',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kDark))),
                Text('₹${(price * qty).toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan)),
              ]));
        }),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Services total',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey)),
          Text('₹${_basePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
        ]),
      ]),
    );
  }

  // ── service selector ───────────────────────────────────────────────────
  Widget _buildServiceSelector() {
    return _SectionCard(
      icon: Icons.category_outlined,
      title: 'Select Service',
      child: Column(children: [
        _buildDropdown<String>(
            value: _selectedService,
            hint: 'Select category',
            items: _kSubCategories.keys.toList(),
            onChanged: (v) => setState(() {
                  _selectedService = v!;
                  _selectedSubCategory = null;
                  _selectedTankSize = null;
                  _selectedCarpenterDesign = null;
                  _selectedTailorDesign = null;
                  _clothSets = 1;
                  _maidDuration = '1 Day';
                  _cleaningItemQty.clear();
                  _genericItemQty.clear();
                  _updatePrice();
                })),
        const SizedBox(height: 10),
        _buildDropdown<String>(
            value: _selectedSubCategory,
            hint: 'Select type',
            items: _kSubCategories[_selectedService] ?? [],
            onChanged: (v) => setState(() {
                  _selectedSubCategory = v;
                  _selectedTankSize = null;
                  _selectedCarpenterDesign = null;
                  _selectedTailorDesign = null;
                  _cleaningItemQty.clear();
                  _genericItemQty.clear();
                  _updatePrice();
                })),
      ]),
    );
  }

  // ── GENERIC ITEM-BASED CARD ────────────────────────────────────────────
  Widget _buildGenericItemsCard() {
    final items = _currentGenericItems;
    final color = _accentColor;
    final categoryLabel = _selectedService;

    const Map<String, IconData> categoryIcons = {
      'Electrician': Icons.electrical_services_rounded,
      'Plumber': Icons.plumbing_rounded,
      'AC Repair': Icons.ac_unit_rounded,
      'Carpenter': Icons.carpenter,
      'Painter': Icons.format_paint_rounded,
      'Salon': Icons.content_cut_rounded,
    };

    return _SectionCard(
      icon: categoryIcons[categoryLabel] ?? Icons.home_repair_service_rounded,
      title: 'Select What You Need',
      accentColor: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [color, color.withOpacity(0.75)]),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Tap items to add. Use + / − to set quantity. Price updates live.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          final aspectRatio = cardWidth / 215;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio),
            itemBuilder: (_, i) {
              final item = items[i];
              final name = item['name'] as String;
              final price = item['price'] as double;
              final unit = item['unit'] as String;
              final imagePath = item['image'] as String;
              final qty = _genericItemQty[name] ?? 0;
              final isSelected = qty > 0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected ? color : const Color(0xFFE8ECE7),
                      width: isSelected ? 2 : 1),
                  boxShadow: [
                    BoxShadow(
                        color: isSelected
                            ? color.withOpacity(0.18)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isSelected ? 14 : 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          SizedBox(
                              width: double.infinity,
                              height: 90,
                              child: Image.asset(imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      height: 90,
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [
                                        color.withOpacity(0.12),
                                        color.withOpacity(0.06)
                                      ])),
                                      child: Icon(
                                          categoryIcons[categoryLabel] ??
                                              Icons.home_repair_service_rounded,
                                          color: color.withOpacity(0.5),
                                          size: 32)))),
                          if (isSelected)
                            ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: Container(
                                    height: 90,
                                    color: color.withOpacity(0.08))),
                          Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('₹${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800)))),
                          if (isSelected)
                            Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 13))),
                        ]),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11.5,
                                              color:
                                                  isSelected ? color : _kDark,
                                              height: 1.3)),
                                      const SizedBox(height: 3),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(unit,
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: color,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                    ]),
                                qty == 0
                                    ? GestureDetector(
                                        onTap: () => setState(() {
                                              _genericItemQty[name] = 1;
                                              _updatePrice();
                                            }),
                                        child: Container(
                                            width: double.infinity,
                                            height: 32,
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                      color,
                                                      color.withOpacity(0.8)
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: color
                                                          .withOpacity(0.3),
                                                      blurRadius: 5,
                                                      offset:
                                                          const Offset(0, 2))
                                                ]),
                                            child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_rounded,
                                                      size: 13,
                                                      color: Colors.white),
                                                  SizedBox(width: 3),
                                                  Text('Add',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12)),
                                                ])))
                                    : Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                            color: color.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: color.withOpacity(0.3))),
                                        child: Row(children: [
                                          GestureDetector(
                                              onTap: () => setState(() {
                                                    if (qty <= 1)
                                                      _genericItemQty
                                                          .remove(name);
                                                    else
                                                      _genericItemQty[name] =
                                                          qty - 1;
                                                    _updatePrice();
                                                  }),
                                              child: Container(
                                                  width: 28,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                      color: color,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .horizontal(
                                                              left: Radius
                                                                  .circular(
                                                                      7))),
                                                  child: const Icon(
                                                      Icons.remove_rounded,
                                                      size: 13,
                                                      color: Colors.white))),
                                          Expanded(
                                              child: Center(
                                                  child: Text('$qty',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: color)))),
                                          GestureDetector(
                                              onTap: () => setState(() {
                                                    _genericItemQty[name] =
                                                        qty + 1;
                                                    _updatePrice();
                                                  }),
                                              child: Container(
                                                  width: 28,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                      color: color,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .horizontal(
                                                              right: Radius
                                                                  .circular(
                                                                      7))),
                                                  child: const Icon(
                                                      Icons.add_rounded,
                                                      size: 13,
                                                      color: Colors.white))),
                                        ])),
                              ]),
                        )),
                      ]),
                ),
              );
            },
          );
        }),
        if (_genericItemCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25))),
            child: Column(children: [
              ..._genericItemQty.entries.where((e) => e.value > 0).map((e) {
                final itemDef = items.firstWhere((it) => it['name'] == e.key,
                    orElse: () => {});
                if (itemDef.isEmpty) return const SizedBox.shrink();
                final lineTotal = e.value * (itemDef['price'] as double);
                return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.key}  ×${e.value}',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: _kDark.withOpacity(0.75))),
                          Text('₹${lineTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ]));
              }),
              const Divider(height: 14, color: Color(0xFFE0E4DF)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(
                      categoryIcons[categoryLabel] ??
                          Icons.home_repair_service_rounded,
                      size: 16,
                      color: color),
                  const SizedBox(width: 6),
                  Text(
                      '$_genericItemCount item${_genericItemCount > 1 ? 's' : ''} selected',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                Text('₹${_genericItemsTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ]),
            ]),
          ),
        ],
        if (_genericItemCount == 0) ...[
          const SizedBox(height: 12),
          Center(
              child: Column(children: [
            Icon(Icons.touch_app_rounded,
                color: Colors.grey.shade300, size: 32),
            const SizedBox(height: 6),
            Text('Tap "Add" on items you need',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ])),
        ],
      ]),
    );
  }

  // ── tank size card ─────────────────────────────────────────────────────
  Widget _buildTankSizeCard() {
    return _SectionCard(
      icon: Icons.water_drop_outlined,
      title: 'Tank Capacity',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Colors.cyan, size: 14),
              SizedBox(width: 6),
              Expanded(
                  child: Text(
                      'Price varies by tank capacity — select the closest size.',
                      style: TextStyle(fontSize: 11, color: Colors.cyan))),
            ])),
        const SizedBox(height: 12),
        ..._kTankSizePrices.entries.map((entry) {
          final selected = _selectedTankSize == entry.key;
          return GestureDetector(
              onTap: () => setState(() {
                    _selectedTankSize = entry.key;
                    _updatePrice();
                  }),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE0F7FA) : _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              selected ? Colors.cyan : const Color(0xFFE0E4DF),
                          width: selected ? 1.5 : 1)),
                  child: Row(children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? Colors.cyan : Colors.transparent,
                            border: Border.all(
                                color: selected ? Colors.cyan : Colors.grey,
                                width: 2)),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12)
                            : null),
                    const SizedBox(width: 12),
                    const Icon(Icons.water_damage_outlined,
                        color: Colors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(entry.key,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFF006064)
                                    : _kDark))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: selected
                                ? Colors.cyan
                                : const Color(0xFFE0E4DF),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('₹${entry.value.toStringAsFixed(0)}',
                            style: TextStyle(
                                color:
                                    selected ? Colors.white : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w700))),
                  ])));
        }),
      ]),
    );
  }

  // ── cleaning items card ────────────────────────────────────────────────
  Widget _buildCleaningItemsCard() {
    final items = _kCleaningItems[_effectiveSub] ?? [];
    final accentColor = _kCleaningColors[_effectiveSub] ?? Colors.cyan;
    return _SectionCard(
      icon: Icons.cleaning_services_rounded,
      title: 'What Needs Cleaning?',
      accentColor: accentColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Tap items to add. Use + / − to set quantity. Price updates live.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ])),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          final aspectRatio = cardWidth / 210;

          return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio),
              itemBuilder: (_, i) {
                final item = items[i];
                final name = item['name'] as String;
                final price = item['price'] as double;
                final unit = item['unit'] as String;
                final imagePath = item['image'] as String;
                final qty = _cleaningItemQty[name] ?? 0;
                final isSelected = qty > 0;
                return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? accentColor
                                : const Color(0xFFE8ECE7),
                            width: isSelected ? 2 : 1),
                        boxShadow: [
                          BoxShadow(
                              color: isSelected
                                  ? accentColor.withOpacity(0.18)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: isSelected ? 10 : 4,
                              offset: const Offset(0, 2))
                        ]),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(children: [
                                SizedBox(
                                    width: double.infinity,
                                    height: 90,
                                    child: Image.asset(imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            height: 90,
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                    colors: [
                                                  accentColor.withOpacity(0.08),
                                                  accentColor.withOpacity(0.04)
                                                ])),
                                            child: Icon(
                                                Icons.cleaning_services_rounded,
                                                color: accentColor
                                                    .withOpacity(0.5),
                                                size: 32)))),
                                if (isSelected)
                                  ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(15)),
                                      child: Container(
                                          height: 90,
                                          color:
                                              accentColor.withOpacity(0.08))),
                                Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.55),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(
                                            '₹${price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700)))),
                                if (isSelected)
                                  Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle),
                                          child: const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 13))),
                              ]),
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: isSelected
                                                        ? accentColor
                                                        : _kDark),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text(unit,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.grey.shade500)),
                                          ]),
                                      if (!isSelected)
                                        SizedBox(
                                            width: double.infinity,
                                            height: 30,
                                            child: ElevatedButton(
                                                onPressed: () => setState(() {
                                                      _cleaningItemQty[name] =
                                                          1;
                                                      _updatePrice();
                                                    }),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        accentColor,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8))),
                                                child: const Text('Add',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700))))
                                      else
                                        Row(children: [
                                          GestureDetector(
                                              onTap: () => setState(() {
                                                    if (qty <= 1)
                                                      _cleaningItemQty
                                                          .remove(name);
                                                    else
                                                      _cleaningItemQty[name] =
                                                          qty - 1;
                                                    _updatePrice();
                                                  }),
                                              child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                      color: accentColor
                                                          .withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7)),
                                                  child: Icon(
                                                      Icons.remove_rounded,
                                                      size: 14,
                                                      color: accentColor))),
                                          Expanded(
                                              child: Center(
                                                  child: Text('$qty',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              accentColor)))),
                                          GestureDetector(
                                              onTap: () => setState(() {
                                                    _cleaningItemQty[name] =
                                                        qty + 1;
                                                    _updatePrice();
                                                  }),
                                              child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                      color: accentColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7)),
                                                  child: const Icon(
                                                      Icons.add_rounded,
                                                      size: 14,
                                                      color: Colors.white))),
                                        ]),
                                    ]),
                              )),
                            ])));
              });
        }),
        if (_cleaningItemCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: accentColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.25))),
            child: Column(children: [
              ..._cleaningItemQty.entries.where((e) => e.value > 0).map((e) {
                final itemDef = items.firstWhere((it) => it['name'] == e.key,
                    orElse: () => {});
                if (itemDef.isEmpty) return const SizedBox.shrink();
                final lineTotal = e.value * (itemDef['price'] as double);
                return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.key}  ×${e.value}',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: _kDark.withOpacity(0.75))),
                          Text('₹${lineTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor)),
                        ]));
              }),
              const Divider(height: 14, color: Color(0xFFE0E4DF)),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(Icons.cleaning_services_rounded,
                      size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                      '$_cleaningItemCount item${_cleaningItemCount > 1 ? 's' : ''} selected',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                Text('₹${_cleaningItemsTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor)),
              ]),
            ]),
          ),
        ],
        if (_cleaningItemCount == 0) ...[
          const SizedBox(height: 12),
          Center(
              child: Column(children: [
            Icon(Icons.touch_app_rounded,
                color: Colors.grey.shade300, size: 32),
            const SizedBox(height: 6),
            Text('Tap "Add" on items you want cleaned',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ])),
        ],
      ]),
    );
  }

  // ── carpenter design card ──────────────────────────────────────────────
  Widget _buildCarpenterDesignCard() {
    final designs =
        _kCarpenterDesigns[_effectiveSub] ?? _kCarpenterDesigns["BookShelf"]!;
    return _SectionCard(
      icon: Icons.design_services_rounded,
      title: 'Choose Design Style',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4E342E), Color(0xFF795548)]),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.carpenter, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Select a design style — our carpenter will create it for you!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ])),
        const SizedBox(height: 16),
        ...designs.map((design) {
          final isSelected = _selectedCarpenterDesign == design["name"];
          final isCustom = design["name"] == "Custom Design";
          return GestureDetector(
              onTap: () =>
                  setState(() => _selectedCarpenterDesign = design["name"]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFBE9E7) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4E342E)
                            : const Color(0xFFE0E4DF),
                        width: isSelected ? 2 : 1)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFFFBE9E7)),
                                child: isCustom
                                    ? const Icon(Icons.edit_note_rounded,
                                        color: Color(0xFF4E342E), size: 28)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(design["image"]!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.chair_alt_rounded,
                                                    color: Color(0xFF4E342E),
                                                    size: 28)))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(design["name"]!,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected
                                              ? const Color(0xFF4E342E)
                                              : _kDark)),
                                  const SizedBox(height: 3),
                                  Text(design["desc"]!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                ])),
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF4E342E)
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF4E342E)
                                            : Colors.grey.shade400,
                                        width: 2)),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                    : null),
                          ])),
                      if (isCustom && isSelected)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: TextField(
                                controller: _carpenterCustomDescCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                    hintText:
                                        'Describe your design: size, wood type, color, style…',
                                    hintStyle: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF4E342E))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF4E342E),
                                            width: 1.5)),
                                    contentPadding: const EdgeInsets.all(12)))),
                    ]),
              ));
        }),
      ]),
    );
  }

  // ── laundry cloth card ─────────────────────────────────────────────────
  Widget _buildLaundryClothCard() {
    return _SectionCard(
      icon: Icons.local_laundry_service_rounded,
      title: 'Number of Cloth Sets',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF006064), Color(0xFF00BCD4)]),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      '₹30 per set — 1 set = shirt + pant / saree / suit etc.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ])),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _counterBtn(
              icon: Icons.remove_rounded,
              enabled: _clothSets > 1,
              onTap: () {
                setState(() => _clothSets--);
                _updatePrice();
              }),
          const SizedBox(width: 24),
          Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyan, width: 1.5)),
              child: Column(children: [
                Text('$_clothSets',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064))),
                const Text('sets',
                    style: TextStyle(fontSize: 11, color: Colors.cyan)),
              ])),
          const SizedBox(width: 24),
          _counterBtn(
              icon: Icons.add_rounded,
              enabled: true,
              onTap: () {
                setState(() => _clothSets++);
                _updatePrice();
              }),
        ]),
        const SizedBox(height: 20),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: _kLightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withOpacity(0.3))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.checkroom_rounded,
                        color: Colors.cyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        '$_clothSets set${_clothSets > 1 ? 's' : ''} × ₹${_kLaundryPricePerSet.toInt()}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark)),
                  ]),
                  Text(
                      '= ₹${(_clothSets * _kLaundryPricePerSet).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyan)),
                ])),
      ]),
    );
  }

  Widget _counterBtn(
      {required IconData icon,
      required VoidCallback onTap,
      required bool enabled}) {
    return GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: enabled ? Colors.cyan : const Color(0xFFE0E4DF),
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                            color: Colors.cyan.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ]
                    : []),
            child: Icon(icon,
                color: enabled ? Colors.white : Colors.grey, size: 24)));
  }

  // ── maid duration card ─────────────────────────────────────────────────
  Widget _buildMaidDurationCard() {
    final options = [
      {
        'value': '1 Day',
        'label': '1 Day',
        'desc': 'One-time maid service',
        'price': _kMaidOneDayPrice,
        'icon': Icons.looks_one_rounded
      },
      {
        'value': '2 Days',
        'label': '2 Days',
        'desc': 'Two consecutive days',
        'price': _kMaidTwoDaysPrice,
        'icon': Icons.looks_two_rounded
      },
      {
        'value': 'Monthly',
        'label': 'Monthly',
        'desc': '26 working days / month',
        'price': _kMaidMonthlyPrice,
        'icon': Icons.calendar_month_rounded
      },
    ];
    return _SectionCard(
      icon: Icons.cleaning_services_rounded,
      title: 'Select Duration',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)]),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Choose how long you need the maid — pricing varies by duration.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ])),
        const SizedBox(height: 16),
        ...options.map((opt) {
          final isSelected = _maidDuration == opt['value'];
          return GestureDetector(
              onTap: () {
                setState(() => _maidDuration = opt['value'] as String);
                _updatePrice();
              },
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE0E4DF),
                          width: isSelected ? 2 : 1)),
                  child: Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(opt['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF43A047),
                            size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(opt['label'] as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF1B5E20)
                                      : _kDark)),
                          const SizedBox(height: 2),
                          Text(opt['desc'] as String,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ])),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE0E4DF),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            '₹${(opt['price'] as double).toStringAsFixed(0)}',
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF43A047)
                                : Colors.transparent,
                            border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF43A047)
                                    : Colors.grey.shade400,
                                width: 2)),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 13)
                            : null),
                  ])));
        }),
      ]),
    );
  }

  // ── tailor design card ─────────────────────────────────────────────────
  Widget _buildTailorDesignCard() {
    final designs =
        _kTailorDesigns[_effectiveSub] ?? _kTailorDesigns["Stitching"]!;
    const customLabels = {
      'Custom Design',
      'Custom Alteration',
      'Custom Fitting'
    };
    return _SectionCard(
      icon: Icons.design_services_rounded,
      title: 'Tailor Details',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF9C27B0)]),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.content_cut_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Choose a design style & tell us about your cloth.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500))),
            ])),
        const SizedBox(height: 16),
        const Text('Choose Design Style',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(height: 10),
        ...designs.map((design) {
          final isSelected = _selectedTailorDesign == design["name"];
          final isCustom = customLabels.contains(design["name"]);
          return GestureDetector(
              onTap: () =>
                  setState(() => _selectedTailorDesign = design["name"]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF3E5F5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF9C27B0)
                            : const Color(0xFFE0E4DF),
                        width: isSelected ? 2 : 1)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFFF3E5F5)),
                                child: isCustom
                                    ? const Icon(Icons.edit_note_rounded,
                                        color: Color(0xFF9C27B0), size: 28)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(design["image"]!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.content_cut_rounded,
                                                    color: Color(0xFF9C27B0),
                                                    size: 28)))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(design["name"]!,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected
                                              ? const Color(0xFF4A148C)
                                              : _kDark)),
                                  const SizedBox(height: 3),
                                  Text(design["desc"]!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                ])),
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF9C27B0)
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF9C27B0)
                                            : Colors.grey.shade400,
                                        width: 2)),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                    : null),
                          ])),
                      if (isCustom && isSelected)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: TextField(
                                controller: _tailorCustomDescCtrl,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                    hintText:
                                        'Describe your design: style, cut, sleeve type…',
                                    hintStyle: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF9C27B0))),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF9C27B0),
                                            width: 1.5)),
                                    contentPadding: const EdgeInsets.all(12)))),
                    ]),
              ));
        }),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFF0F0F0)),
        const SizedBox(height: 14),
        const Text('Describe Your Cloth / Fabric',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(height: 8),
        TextField(
            controller: _tailorClothDescCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
                hintText:
                    'e.g. Cotton fabric, blue colour, 2 metres, full-sleeve blouse…',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF9C27B0), width: 1.5)),
                contentPadding: const EdgeInsets.all(14))),
        const SizedBox(height: 14),
        const Text('Upload Cloth Photo (Optional)',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kDark)),
        const SizedBox(height: 8),
        GestureDetector(
            onTap: () => _showImageOptions(isTailor: true),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: _tailorClothImage != null ? 180 : 100,
                decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _tailorClothImage != null
                            ? const Color(0xFF9C27B0)
                            : const Color(0xFFE0E4DF),
                        width: _tailorClothImage != null ? 1.5 : 1)),
                child: _tailorClothImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF3E5F5),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add_a_photo_outlined,
                                    color: Color(0xFF9C27B0), size: 20)),
                            const SizedBox(height: 8),
                            const Text('Add a photo of your cloth',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            const Text(
                                'Helps the tailor understand fabric & colour',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ])
                    : Stack(children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_tailorClothImage!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover)),
                        Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                                onTap: () =>
                                    setState(() => _tailorClothImage = null),
                                child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16)))),
                      ]))),
      ]),
    );
  }

  // ── location card ──────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return _SectionCard(
        icon: Icons.location_on_outlined,
        title: 'Service Location',
        child: TextField(
            controller: _locCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
                hintText: 'Enter your address',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: _kBg,
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.cyan)))
                    : IconButton(
                        icon: const Icon(Icons.my_location_rounded,
                            color: Colors.cyan, size: 20),
                        onPressed: _getCurrentLocation),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.cyan, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12))));
  }

  // ── issue details card ─────────────────────────────────────────────────
  Widget _buildIssueDetailsCard() {
    return _SectionCard(
        icon: Icons.description_outlined,
        title: 'Issue Details',
        child: Column(children: [
          GestureDetector(
              onTap: () => _showImageOptions(),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: _selectedImage != null ? 180 : 100,
                  decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _selectedImage != null
                              ? Colors.cyan
                              : const Color(0xFFE0E4DF),
                          width: _selectedImage != null ? 1.5 : 1)),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: _kLightGreen,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.add_a_photo_outlined,
                                      color: Colors.cyan, size: 20)),
                              const SizedBox(height: 8),
                              const Text('Add a photo of the issue',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              const Text('Optional · helps worker prepare',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ])
                      : Stack(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_selectedImage!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover)),
                          Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16)))),
                        ]))),
          const SizedBox(height: 12),
          TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                  hintText:
                      'Describe the issue (e.g. tap leaking, fan not working)…',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E4DF))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.cyan, width: 1.5)),
                  contentPadding: const EdgeInsets.all(14))),
        ]));
  }

  // ── promo card ─────────────────────────────────────────────────────────
  Widget _buildPromoCard() {
    return _SectionCard(
        icon: Icons.local_offer_outlined,
        title: 'Promo Code',
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: _promoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: _kBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E4DF))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFFE0E4DF))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Colors.cyan, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11)))),
          const SizedBox(width: 10),
          SizedBox(
              height: 44,
              child: ElevatedButton(
                  onPressed: _applyPromo,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                  child: const Text('Apply',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)))),
        ]));
  }

  // ── bill card ──────────────────────────────────────────────────────────
  Widget _buildBillCard() {
    final color = _accentColor;
    return _SectionCard(
        icon: Icons.receipt_long_outlined,
        title: 'Bill Summary',
        child: Column(children: [
          if (_isGenericItemBased && _genericItemCount > 0) ...[
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  ..._genericItemQty.entries.where((e) => e.value > 0).map((e) {
                    final itemDef = _currentGenericItems.firstWhere(
                        (it) => it['name'] == e.key,
                        orElse: () => {});
                    if (itemDef.isEmpty) return const SizedBox.shrink();
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${e.key} ×${e.value}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF555555))),
                              Text(
                                  '₹${(e.value * (itemDef['price'] as double)).toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ]));
                  }),
                ])),
            const SizedBox(height: 10),
          ],
          if (_isItemBasedCleaning && _cleaningItemCount > 0) ...[
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  ...(_kCleaningItems[_effectiveSub] ?? []).map((item) {
                    final qty = _cleaningItemQty[item['name'] as String] ?? 0;
                    if (qty == 0) return const SizedBox.shrink();
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['name']} ×$qty',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF555555))),
                              Text(
                                  '₹${(qty * (item['price'] as double)).toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ]));
                  }),
                ])),
            const SizedBox(height: 10),
          ],
          if (_isLaundry) ...[
            Row(children: [
              const Icon(Icons.checkroom_rounded, size: 13, color: Colors.cyan),
              const SizedBox(width: 4),
              Text(
                  '$_clothSets set${_clothSets > 1 ? 's' : ''} × ₹${_kLaundryPricePerSet.toInt()}',
                  style: const TextStyle(fontSize: 12, color: Colors.cyan))
            ]),
            const SizedBox(height: 6),
          ],
          if (_isMaid) ...[
            Row(children: [
              const Icon(Icons.cleaning_services_rounded,
                  size: 13, color: Color(0xFF43A047)),
              const SizedBox(width: 4),
              Text('Duration: $_maidDuration',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF43A047)))
            ]),
            const SizedBox(height: 6),
          ],
          if (_isTankCleaning && _selectedTankSize != null) ...[
            Row(children: [
              const Icon(Icons.water_drop_outlined,
                  size: 13, color: Colors.cyan),
              const SizedBox(width: 4),
              Text('Tank: $_selectedTankSize',
                  style: const TextStyle(fontSize: 12, color: Colors.cyan))
            ]),
            const SizedBox(height: 6),
          ],
          _billRow('Service charge', '₹${_basePrice.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Platform fee',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            _isGoldMember
                ? Row(children: [
                    Text('₹${_kPlatformFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough)),
                    const SizedBox(width: 6),
                    const Text('FREE',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB800))),
                  ])
                : Text('₹${_kPlatformFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
          if (_isGoldMember) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.workspace_premium,
                    size: 14, color: Color(0xFFFFB800)),
                const SizedBox(width: 4),
                Text('Gold ${_kGoldDiscountPercent.toInt()}% off',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFFFB800))),
              ]),
              Text('-₹${_goldDiscount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFB800))),
            ]),
          ],
          if (_promoDiscount > 0) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Promo discount',
                  style: TextStyle(fontSize: 13, color: Colors.cyan)),
              Text('-₹${_promoDiscount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.cyan)),
            ]),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total payable',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('₹${_total.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color))),
          ]),
        ]));
  }

  // ── payment card ───────────────────────────────────────────────────────
  Widget _buildPaymentCard() {
    return _SectionCard(
        icon: Icons.payment_outlined,
        title: 'Payment Method',
        child: Row(children: [
          _paymentOption('COD', 'Cash on Delivery', Icons.money_rounded),
          const SizedBox(width: 10),
          _paymentOption('ONLINE', 'Pay Online', Icons.credit_card_rounded),
        ]));
  }

  // ── confirm bar ────────────────────────────────────────────────────────
  Widget _buildConfirmBar() {
    final color = _accentColor;
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ]),
        child: SafeArea(
            top: false,
            child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendRequest,
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isGoldMember ? const Color(0xFFFFB800) : color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(
                                    _paymentMethod == 'ONLINE'
                                        ? Icons.flash_on_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                    _paymentMethod == 'ONLINE'
                                        ? 'Pay ₹${_total.toStringAsFixed(0)} & Confirm'
                                        : 'Confirm Booking · ₹${_total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ])))));
  }

  // ── helpers ────────────────────────────────────────────────────────────
  Widget _billRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final sel = _paymentMethod == value;
    return Expanded(
        child: GestureDetector(
            onTap: () => setState(() => _paymentMethod = value),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: sel ? _kLightGreen : _kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel ? Colors.cyan : const Color(0xFFE0E4DF),
                        width: sel ? 1.5 : 1)),
                child: Column(children: [
                  Icon(icon, color: sel ? Colors.cyan : Colors.grey, size: 24),
                  const SizedBox(height: 6),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.cyan : Colors.grey)),
                ]))));
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4DF))),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                hint: Text(hint,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey),
                items: items
                    .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(e.toString(),
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: onChanged)));
  }
}

// ─────────────────────────────────────────────
//  REUSABLE SECTION CARD
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.accentColor,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Colors.cyan;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECE7))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ]),
          const SizedBox(height: 12),
          child,
        ]));
  }
}
