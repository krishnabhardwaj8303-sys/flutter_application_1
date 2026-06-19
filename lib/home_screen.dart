import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'cart_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'subcategory_screen.dart';
import 'service_details.dart';
import 'book_service.dart';
import 'all_categories_screen.dart';
import 'notification_screen.dart';
import 'schedule_booking_screen.dart';

// ─── Sub-categories data ──────────────────────────────────────────────────────
final Map<String, List<Map<String, String>>> subCategories = {
  "Electrician": [
    {"name": "Fan Repair", "image": "assets/fan repair.webp"},
    {"name": "Wiring", "image": "assets/Wiring.webp"},
    {"name": "Light Installation", "image": "assets/light replacement.webp"},
    {"name": "Switch and Socket Installation", "image": "assets/ss.webp"},
    {"name": "MCB replacement", "image": "assets/MCB replacement.webp"},
    {"name": "Tv Installation", "image": "assets/Tv installation.webp"},
    {"name": "Fan Installation", "image": "assets/fan installation.webp"},
    {"name": "Fan Replacement", "image": "assets/fan replacement.webp"},
    {"name": "Switch Replacement", "image": "assets/switch.webp"},
    {"name": "Socket Replacement", "image": "assets/ss.webp"},
    {"name": "Board Installation", "image": "assets/switch board.webp"},
    {"name": "Holder Replacement", "image": "assets/holder replacement.webp"},
    {
      "name": "Wall/Ceiling Light Replacement",
      "image": "assets/ceiling light.webp"
    },
    {"name": "Doorbell Installation", "image": "assets/Doorbell.webp"},
    {"name": "Doorbell Replacement", "image": "assets/Doorbell.webp"},
    {"name": "Geyser Installation", "image": "assets/geyser.webp"},
    {
      "name": "Washing Machine Repairing",
      "image": "assets/washing machine.webp"
    },
    {"name": "Refrigerator Repairing", "image": "assets/Refrigerator.webp"},
    {"name": "Camera Installation", "image": "assets/camera.webp"},
    {
      "name": "Refrigerator Gas Filling",
      "image": "assets/Refrigerator gas.webp"
    },
  ],
  "Plumber": [
    {"name": "Basin Installation", "image": "assets/Basin installation.webp"},
    {
      "name": "Bathroom Accessories Installation",
      "image": "assets/Bathroom accessories installation.webp"
    },
    {
      "name": "Flush Tank Installation",
      "image": "assets/flush tank installation.webp"
    },
    {"name": "Jet Spray Repair", "image": "assets/jet spray repair.webp"},
    {"name": "Pipeline Repair", "image": "assets/pipeline repair.webp"},
    {"name": "Shower Installation", "image": "assets/shower installation.webp"},
    {
      "name": "Shower Repair and Replacement",
      "image": "assets/shower installation.webp"
    },
    {"name": "Sink Installation", "image": "assets/Sink installation.webp"},
    {"name": "Tap Repair", "image": "assets/tap repair.webp"},
    {
      "name": "Toilet Seat Cover Replacement",
      "image": "assets/toilet seat cover replacement.webp"
    },
    {"name": "Waste Pipe Replacement", "image": "assets/waste pipe.webp"},
    {
      "name": "Water Tank Installation",
      "image": "assets/water tank installation.webp"
    },
    {
      "name": "Western Toilet Seat Replacement",
      "image": "assets/westearn.webp"
    },
    {"name": "Flush Tank Repair", "image": "assets/flush tank repair.webp"},
  ],
  "Cleaning": [
    {"name": "Home Cleaning", "image": "assets/house cleaning.webp"},
    {"name": "Bathroom Cleaning", "image": "assets/bathroom cleaning.webp"},
    {"name": "Kitchen Cleaning", "image": "assets/kitchen cleaning.webp"},
    {"name": "Water Tank Cleaning", "image": "assets/water tank cleaning.webp"},
    {"name": "Deep Cleaning", "image": "assets/Deep cleaning.webp"},
    {"name": "Vehicle Cleaning", "image": "assets/vehicle cleaning.webp"},
    {
      "name": "Refrigerator Cleaning",
      "image": "assets/refrigerator cleaning.webp"
    },
    {"name": "Shop Cleaning", "image": "assets/shop.webp"},
  ],
  "Carpenter": [
    {"name": "BookShelf", "image": "assets/book.webp"},
    {"name": "Door and Window", "image": "assets/window.webp"},
    {"name": "Chair and Table", "image": "assets/chair.webp"},
    {"name": "Almary", "image": "assets/almary.webp"},
    {"name": "Bed", "image": "assets/bed.webp"},
  ],
  "AC Repair": [
    {"name": "AC Repair", "image": "assets/ac repair.webp"},
    {"name": "Gas Refill", "image": "assets/gas.webp"},
    {"name": "AC Installation", "image": "assets/ac insta.webp"},
    {"name": "Water Leaking", "image": "assets/water leaking.webp"},
    {"name": "Compressor Change", "image": "assets/compressor.webp"},
    {"name": "AC Moving", "image": "assets/move.webp"},
  ],
  "Maid": [
    {"name": "Kitchen Maid", "image": "assets/kitchen maid.webp"},
    {"name": "House Maid", "image": "assets/house maid.webp"},
    {"name": "Child Care Maid", "image": "assets/child care.webp"},
  ],
  "Phone Repairing": [
    {"name": "Screen Changing", "image": "assets/screen.webp"},
    {"name": "Phone Exchange", "image": "assets/phone ex.webp"},
    {"name": "Full Phone Repairing", "image": "assets/full phone repair.webp"},
    {"name": "Speaker Repairing", "image": "assets/speaker.webp"},
  ],
  "Salon": [
    {"name": "Hair Cut", "image": "assets/hair.webp"},
    {"name": "Hair Wash", "image": "assets/wash.webp"},
    {"name": "Makeup", "image": "assets/makeup.webp"},
  ],
  "Painter": [
    {"name": "Full House", "image": "assets/whole house.webp"},
    {"name": "One Room", "image": "assets/one room.webp"},
    {"name": "Window And Door", "image": "assets/window and door.webp"},
    {"name": "Ceiling Painting", "image": "assets/ceiling paint.webp"},
  ],
  "Laundry and Dry Cleaning": [
    {"name": "Pressing", "image": "assets/pressing.webp"},
    {"name": "Drying", "image": "assets/dring.webp"},
    {"name": "Cleaning", "image": "assets/cleaningng.webp"},
  ],
  "Staff(Boy/Girls)": [
    {"name": "Party Boy/Girl", "image": "assets/party.webp"},
    {"name": "Wedding Boy/Girl", "image": "assets/waiter.webp"},
    {"name": "Cafe Staff", "image": "assets/cafe.webp"},
    {"name": "Hotel Staff", "image": "assets/hotel.webp"},
    {"name": "Shop Staff", "image": "assets/shop.webp"},
  ],
  "Tailor": [
    {"name": "Fitting any type cloth", "image": "assets/fitting_cloth.webp"},
    {"name": "Man Cloth", "image": "assets/mancloth.webp"},
    {"name": "Female Cloth", "image": "assets/femalecloth.webp"},
    {"name": "Bed Sheet", "image": "assets/bedsheet.webp"},
    {"name": "Stitching", "image": "assets/simple kurti.webp"},
    {"name": "Blouse Stitching", "image": "assets/plain blouse.webp"},
    {"name": "Suit Stitching", "image": "assets/formal suit.webp"},
    {"name": "Alteration", "image": "assets/shorten.webp"},
    {"name": "Kids Dress", "image": "assets/school uniform.webp"},
  ],
};

// ─── Theme constants ──────────────────────────────────────────────────────────
class _C {
  static const cyan1 = Color(0xFF00BCD4);
  static const cyan2 = Color(0xFF0097A7);
  static const cyan3 = Color(0xFF006064);
  static const cyanLight = Color(0xFFE0F7FA);
  static const bg = Color(0xFFF8FFFE);
  static const white = Colors.white;
  static const dark = Color(0xFF0D1B1E);
  static const muted = Color(0xFF607D8B);
  static const card = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE0F2F4);
}

// ─── FIX: Canonical lowercase category names that match Firestore ─────────────
// Workers register with lowercase category strings (e.g. "cleaning").
// This map converts display names → what's actually stored in Firestore.
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
    "dry cleaning"
  ],
  "Staff(Boy/Girls)": [
    "staff",
    "Staff",
    "Staff(Boy/Girls)",
    "staff(boy/girls)"
  ],
  "Tailor": ["tailor", "Tailor"],
};

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final void Function(int i) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Map<String, String>> searchResults = [];
  bool isSearching = false;
  bool _searchFocused = false;
  bool _locationLoading = false;
  bool _isCheckingAvailability = false;

  String locationText = "Detecting location...";

  Position? _cachedPosition;

  int _unreadCount = 0;

  late AnimationController _bannerAnim;
  late Animation<double> _bannerFade;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final services = [
    {"image": "assets/cleaning.webp", "name": "Cleaning", "icon": "🧹"},
    {"image": "assets/plumber.webp", "name": "Plumber", "icon": "🔧"},
    {"image": "assets/electrician.webp", "name": "Electrician", "icon": "⚡"},
    {"image": "assets/carpenter.webp", "name": "Carpenter", "icon": "🪚"},
    {"image": "assets/painter.webp", "name": "Painter", "icon": "🖌️"},
    {"image": "assets/ac repair.webp", "name": "AC Repair", "icon": "❄️"},
    {"image": "assets/salon.webp", "name": "Salon", "icon": "✂️"},
    {"image": "assets/maid.webp", "name": "Maid", "icon": "🏠"},
    {"image": "assets/phone.webp", "name": "Phone Repairing", "icon": "📱"},
    {
      "image": "assets/laundry and dry cleaningg.jpeg",
      "name": "Laundry and Dry Cleaning",
      "icon": "👔"
    },
    {"image": "assets/staff.webp", "name": "Staff(Boy/Girls)", "icon": "👥"},
    {"image": "assets/tailor.webp", "name": "Tailor", "icon": "🧵"},
  ];

  final List<Map<String, dynamic>> _offers = [
    {
      "title": "AC Service\n& Repair",
      "subtitle": "Starting ₹299",
      "gradient": [Color(0xFF00BCD4), Color(0xFF006064)],
      "icon": "❄️",
      "tag": "Most Booked",
    },
    {
      "title": "Deep Home\nCleaning",
      "subtitle": "Starting ₹499",
      "gradient": [Color(0xFF0097A7), Color(0xFF004D40)],
      "icon": "🧹",
      "tag": "20% Off",
    },
    {
      "title": "Salon at\nHome",
      "subtitle": "Starting ₹199",
      "gradient": [Color(0xFF00838F), Color(0xFF006064)],
      "icon": "✂️",
      "tag": "New",
    },
  ];

  static const Map<String, Map<String, String>> _popularRoutes = {
    "Home Cleaning": {
      "category": "Cleaning",
      "subCategory": "Home Cleaning",
    },
    "AC Service & Repair": {
      "category": "AC Repair",
      "subCategory": "AC Repair",
    },
    "Salon at Home": {
      "category": "Salon",
      "subCategory": "Hair Cut",
    },
  };

  // ═══════════════════════════════════════════════════════
  //  INIT
  // ═══════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();

    _bannerAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bannerFade = CurvedAnimation(parent: _bannerAnim, curve: Curves.easeOut);
    _bannerAnim.forward();

    _searchFocus.addListener(
        () => setState(() => _searchFocused = _searchFocus.hasFocus));

    _initAfterAuth();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  Future<void> _initAfterAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Token refresh error: $e');
    }
    _setupFCM();
    _listenUnreadCount();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _bannerAnim.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  REAL-TIME UNREAD COUNT
  // ═══════════════════════════════════════════════════════
  void _listenUnreadCount() {
    if (_uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _unreadCount = snap.docs.length);
    }, onError: (e) {
      debugPrint('Notification listener error: $e');
    });
  }

  // ═══════════════════════════════════════════════════════
  //  FCM SETUP
  // ═══════════════════════════════════════════════════════
  void _setupFCM() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null && _uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .update({'fcmToken': token});
      } catch (e) {
        debugPrint('FCM token update error: $e');
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final title = message.notification?.title ?? "New Notification";
      final body = message.notification?.body ?? "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              if (body.isNotEmpty)
                Text(body,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          backgroundColor: _C.cyan2,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "View",
            textColor: Colors.white,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()));
    });
  }

  // ═══════════════════════════════════════════════════════
  //  AUTO DETECT LOCATION
  // ═══════════════════════════════════════════════════════
  Future<void> _autoDetectLocation() async {
    if (!mounted) return;
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationPopup(reason: _LocationDenyReason.serviceDisabled);
        setState(() => locationText = "Location off");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showLocationPopup(reason: _LocationDenyReason.permissionDenied);
        setState(() => locationText = "Location denied");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationPopup(reason: _LocationDenyReason.permissionPermanent);
        setState(() => locationText = "Location blocked");
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _cachedPosition = position;

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          locationText =
              "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => locationText = "Tap to set location");
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  LOCATION POPUP
  // ═══════════════════════════════════════════════════════
  void _showLocationPopup({required _LocationDenyReason reason}) {
    if (!mounted) return;
    final bool isServiceOff = reason == _LocationDenyReason.serviceDisabled;
    final bool isPermanent = reason == _LocationDenyReason.permissionPermanent;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.cyan1.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                isServiceOff
                    ? "Location Services Off"
                    : isPermanent
                        ? "Location Blocked"
                        : "Allow Location Access",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _C.dark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isServiceOff
                    ? "Your device's location is turned off. Please enable it in Settings."
                    : isPermanent
                        ? "Location was permanently denied. Go to App Settings and enable it."
                        : "We need your location to show services near you.",
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(
                    isServiceOff
                        ? Icons.settings_rounded
                        : isPermanent
                            ? Icons.settings_applications_rounded
                            : Icons.location_on_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isServiceOff || isPermanent
                        ? "Open Settings"
                        : "Allow Location",
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.cyan1,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (isServiceOff) {
                      await Geolocator.openLocationSettings();
                    } else if (isPermanent) {
                      await Geolocator.openAppSettings();
                    } else {
                      await _autoDetectLocation();
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openLocationSheet();
                },
                child: const Text(
                  "Enter Location Manually",
                  style: TextStyle(
                      color: _C.cyan2,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  MANUAL LOCATION SHEET
  // ═══════════════════════════════════════════════════════
  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationPopup(reason: _LocationDenyReason.serviceDisabled);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showLocationPopup(reason: _LocationDenyReason.permissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationPopup(reason: _LocationDenyReason.permissionPermanent);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _cachedPosition = position;

      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          locationText =
              "${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
        });
      }
    } catch (_) {
      if (mounted) setState(() => locationText = "Tap to set location");
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _openLocationSheet() {
    final manualController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Select Location",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _C.dark)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await _getCurrentLocation();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _C.cyanLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.cyan1.withOpacity(0.4)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.my_location_rounded, color: _C.cyan1, size: 22),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Use Current Location",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _C.cyan2,
                                fontSize: 14)),
                        Text("Fast & accurate via GPS",
                            style: TextStyle(fontSize: 12, color: _C.muted)),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: _C.cyan2),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Text("Or enter manually",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: manualController,
                decoration: InputDecoration(
                  hintText: "e.g. Pune, Mumbai, Itarsi...",
                  prefixIcon:
                      const Icon(Icons.search, color: _C.cyan1, size: 20),
                  filled: true,
                  fillColor: _C.bg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.divider)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.divider)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _C.cyan1, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.cyan1,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (manualController.text.isNotEmpty) {
                      _cachedPosition = null;
                      setState(() => locationText = manualController.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Confirm Location",
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HAVERSINE DISTANCE HELPER
  // ═══════════════════════════════════════════════════════
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  // ═══════════════════════════════════════════════════════
  //  CHECK IF ANY WORKER DOC IS WITHIN 10 KM
  // ═══════════════════════════════════════════════════════
  bool _anyWorkerWithin10km(
      List<QueryDocumentSnapshot<Object?>> docs, Position userPos) {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      double? workerLat, workerLng;

      if (data['location'] is GeoPoint) {
        final gp = data['location'] as GeoPoint;
        workerLat = gp.latitude;
        workerLng = gp.longitude;
      } else if (data['latitude'] != null && data['longitude'] != null) {
        workerLat = (data['latitude'] as num).toDouble();
        workerLng = (data['longitude'] as num).toDouble();
      }

      // If worker has no location stored, treat as available (fail-open)
      if (workerLat == null || workerLng == null) {
        debugPrint('Worker ${doc.id} has no location – treating as available');
        return true;
      }

      final dist = _haversineKm(
          userPos.latitude, userPos.longitude, workerLat, workerLng);

      debugPrint('Worker ${doc.id} is ${dist.toStringAsFixed(2)} km away');

      if (dist <= 10.0) return true;
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════
  //  ✅ FIXED: SERVICE AVAILABILITY CHECK
  //
  //  KEY FIXES:
  //  1. Queries 'workers' collection (not 'users')
  //  2. Uses arrayContains because 'category' field is a List<String>
  //  3. Tries ALL known aliases for the category (exact, lowercase, variants)
  //     via _kCategoryAliases — never passes subCategory to Firestore
  //  4. Falls back to any online worker if no category match found
  //  5. Fails open (returns true) if GPS unavailable — never blocks users
  // ═══════════════════════════════════════════════════════
  Future<bool> _checkServiceAvailability(String category) async {
    try {
      // ── Step 1: resolve user position ──────────────────────────────────────
      Position? userPos = _cachedPosition;
      if (userPos == null) {
        try {
          final svcEnabled = await Geolocator.isLocationServiceEnabled();
          final perm = await Geolocator.checkPermission();
          if (svcEnabled &&
              perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            userPos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 6),
            );
            _cachedPosition = userPos;
          }
        } catch (e) {
          debugPrint('Could not get position for availability check: $e');
        }
      }

      // ── Step 2: build all alias strings to try for this category ───────────
      // IMPORTANT: We only query by MAIN CATEGORY (e.g. "cleaning").
      // Sub-categories like "Home Cleaning" are UI-only — workers never
      // register with sub-category strings in their 'category' array.
      final List<String> aliases =
          _kCategoryAliases[category] ?? [category, category.toLowerCase()];

      // ── Step 3: try each alias until we find matching workers ───────────────
      QuerySnapshot<Map<String, dynamic>>? matchedSnap;

      for (final alias in aliases) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('workers') // ✅ FIXED: correct collection
              .where('category',
                  arrayContains: alias) // ✅ FIXED: arrayContains for List
              .get();

          if (snap.docs.isNotEmpty) {
            debugPrint(
                '✅ Found ${snap.docs.length} worker(s) for category "$alias"');
            matchedSnap = snap;
            break;
          }
        } catch (e) {
          debugPrint('Query failed for arrayContains "$alias": $e');
        }
      }

      // ── Step 4: fallback — any online worker (fail-open safety net) ─────────
      if (matchedSnap == null || matchedSnap.docs.isEmpty) {
        debugPrint(
            '⚠️ No workers found for "$category". Trying isOnline fallback...');
        try {
          final fallbackSnap = await FirebaseFirestore.instance
              .collection('workers')
              .where('isOnline', isEqualTo: true)
              .limit(1)
              .get();

          if (fallbackSnap.docs.isNotEmpty) {
            debugPrint(
                '✅ Fallback: online workers found – treating as available');
            return true;
          }
        } catch (e) {
          debugPrint('Fallback query error: $e');
        }

        debugPrint('❌ No workers found for "$category"');
        return false;
      }

      // ── Step 5: radius check if GPS available ───────────────────────────────
      if (userPos != null) {
        final withinRange = _anyWorkerWithin10km(matchedSnap.docs, userPos);
        debugPrint(withinRange
            ? '✅ Worker within 10km for "$category"'
            : '❌ No worker within 10km for "$category"');
        return withinRange;
      }

      // ── Step 6: no GPS → fail-open ──────────────────────────────────────────
      debugPrint(
          '⚠️ No GPS – skipping radius check for "$category". Treating as available.');
      return true;
    } catch (e) {
      debugPrint('Availability check unexpected error: $e');
      return true; // fail-open on unexpected error
    }
  }

  // ═══════════════════════════════════════════════════════
  //  NOT AVAILABLE POPUP
  // ═══════════════════════════════════════════════════════
  void _showNotAvailablePopup({String? serviceName}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.location_off_rounded,
                  size: 36, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            Text(
              serviceName != null
                  ? "$serviceName Not Available"
                  : "Service Not Available",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: _C.dark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Sorry, we haven't reached $locationText yet.\nWe're expanding soon 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.cyan1,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("We'll notify you when we arrive 🔔")),
                  );
                },
                child: const Text("Notify Me When Available",
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Maybe Later",
                  style: TextStyle(color: _C.muted, fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SHARED LOADING DIALOG
  // ═══════════════════════════════════════════════════════
  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _C.cyan1),
            SizedBox(height: 14),
            Text("Checking availability...",
                style: TextStyle(color: _C.muted, fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  void _dismissLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ═══════════════════════════════════════════════════════
  //  SEARCH
  // ═══════════════════════════════════════════════════════
  void _searchService(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        isSearching = false;
      });
      return;
    }
    final List<Map<String, String>> results = [];
    for (var service in services) {
      if ((service["name"] as String)
          .toLowerCase()
          .contains(query.toLowerCase())) {
        results.add({"name": service["name"] as String, "type": "category"});
      }
    }
    subCategories.forEach((category, subList) {
      for (var sub in subList) {
        if (sub["name"]!.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            "name": sub["name"]!,
            "category": category,
            "type": "sub",
          });
        }
      }
    });
    setState(() {
      searchResults = results;
      isSearching = true;
    });
  }

  // ═══════════════════════════════════════════════════════
  //  SEARCH RESULT TAP
  //  ✅ FIXED: always checks by main category, never subCategory
  // ═══════════════════════════════════════════════════════
  Future<void> _onSearchResultTap(Map<String, String> item) async {
    if (!mounted || _isCheckingAvailability) return;

    final bool isCategory = item["type"] == "category";
    // Always resolve to the main category for the Firestore query
    final String category = isCategory ? item["name"]! : item["category"]!;
    final String subCategory = item["name"]!;

    setState(() => _isCheckingAvailability = true);
    _showLoadingDialog();

    // ✅ Only pass main category — never subCategory — to Firestore
    final bool isAvailable = await _checkServiceAvailability(category);

    _dismissLoadingDialog();
    if (mounted) setState(() => _isCheckingAvailability = false);

    if (!mounted) return;

    if (!isAvailable) {
      _showNotAvailablePopup(
        serviceName: isCategory ? category : subCategory,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookServiceScreen(
          category: category,
          subCategory: subCategory,
          serviceName: '',
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SERVICE TAP (grid / category cards)
  //  ✅ FIXED: navigates to SubCategoryScreen without re-checking
  //  availability there — the check happens ONCE here, then
  //  SubCategoryScreen does its own check only when "Book Now" is tapped.
  // ═══════════════════════════════════════════════════════
  Future<void> _onServiceTap(String category) async {
    if (!mounted || _isCheckingAvailability) return;

    setState(() => _isCheckingAvailability = true);
    _showLoadingDialog();

    final bool isAvailable = await _checkServiceAvailability(category);

    _dismissLoadingDialog();
    if (mounted) setState(() => _isCheckingAvailability = false);

    if (!mounted) return;

    if (!isAvailable) {
      _showNotAvailablePopup(serviceName: category);
      return;
    }

    if (subCategories.containsKey(category)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubCategoryScreen(
            categoryName: category,
            subList: subCategories[category]!,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(serviceName: category)),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  POPULAR SERVICE TAP → instant booking
  // ═══════════════════════════════════════════════════════
  Future<void> _onPopularServiceTap(Map<String, String> p) async {
    if (!mounted || _isCheckingAvailability) return;

    final route = _popularRoutes[p["name"]];

    if (route == null) {
      _onServiceTap(p["name"]!);
      return;
    }

    setState(() => _isCheckingAvailability = true);
    _showLoadingDialog();

    // ✅ Only pass main category — never subCategory
    final bool isAvailable =
        await _checkServiceAvailability(route["category"]!);

    _dismissLoadingDialog();
    if (mounted) setState(() => _isCheckingAvailability = false);

    if (!mounted) return;

    if (!isAvailable) {
      _showNotAvailablePopup(serviceName: p["name"]);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookServiceScreen(
          category: route["category"]!,
          subCategory: route["subCategory"]!,
          serviceName: '',
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(children: [
          _buildTopHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSearching) _buildSearchResults(),
                  if (!isSearching) ...[
                    FadeTransition(
                        opacity: _bannerFade, child: _buildOffersBanner()),
                    const SizedBox(height: 8),
                    _buildScheduleStrip(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Our Services", null),
                    const SizedBox(height: 12),
                    _buildServicesGrid(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Popular Services", () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllCategoriesScreen()));
                    }),
                    const SizedBox(height: 12),
                    _buildPopularList(),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── TOP HEADER ───────────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006064), Color(0xFF00BCD4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/logooo.jpeg",
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openLocationSheet,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _locationLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()),
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Color(0xFFFF5252), shape: BoxShape.circle),
                        child: Text(
                          _unreadCount > 9 ? "9+" : "$_unreadCount",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text("Hello 👋  ",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text("What do you need today?",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _searchFocused
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: (v) {
                    _searchService(v);
                    setState(() {});
                  },
                  style: const TextStyle(
                      color: _C.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Search plumber, electrician, AC repair...",
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: _C.cyan2, size: 22),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: _C.muted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _searchService("");
                              setState(() {});
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: _C.cyan1, width: 1.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH RESULTS ───────────────────────────────────────────────────────────
  Widget _buildSearchResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            "${searchResults.length} result${searchResults.length != 1 ? 's' : ''} for \"${_searchCtrl.text}\"",
            style: const TextStyle(
                fontSize: 13, color: _C.muted, fontWeight: FontWeight.w500),
          ),
        ),
        if (searchResults.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Text("🔍", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text("No services found",
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _C.dark)),
                const SizedBox(height: 4),
                Text("Try different keywords",
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final item = searchResults[index];
              final isCategory = item["type"] == "category";
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.divider),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 6)
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: _C.cyanLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      isCategory
                          ? Icons.category_outlined
                          : Icons.home_repair_service_outlined,
                      color: _C.cyan1,
                      size: 20,
                    ),
                  ),
                  title: Text(item["name"]!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _C.dark)),
                  subtitle: Text(
                    isCategory ? "Category" : item["category"] ?? "",
                    style: const TextStyle(fontSize: 12, color: _C.muted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: _C.cyanLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: _C.cyan2),
                  ),
                  onTap: () => _onSearchResultTap(item),
                ),
              );
            },
          ),
      ]),
    );
  }

  // ─── OFFERS BANNER ────────────────────────────────────────────────────────────
  Widget _buildOffersBanner() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            "assets/bannerr.webp",
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF006064), Color(0xFF00BCD4)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🏠", style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text("Professional Home Services",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text("Trusted · Verified · On-Time",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 118,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          itemCount: _offers.length,
          itemBuilder: (context, i) {
            final o = _offers[i];
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: o["gradient"] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: (o["gradient"] as List<Color>)[0].withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o["icon"] as String,
                          style: const TextStyle(fontSize: 22)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(o["tag"] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o["title"] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.3)),
                      const SizedBox(height: 2),
                      Text(o["subtitle"] as String,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ─── SCHEDULE STRIP ───────────────────────────────────────────────────────────
  Widget _buildScheduleStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _C.cyanLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.cyan1.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _C.cyan1, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Schedule a Service",
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _C.dark)),
                  Text("Book at your convenient time 📅",
                      style: TextStyle(fontSize: 12, color: _C.muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.cyan2),
          ]),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _C.dark)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.cyanLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("See All",
                    style: TextStyle(
                        color: _C.cyan2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ─── SERVICES GRID (3 columns) ────────────────────────────────────────────────
  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.80,
        ),
        itemBuilder: (context, index) {
          final item = services[index];
          return GestureDetector(
            onTap: () => _onServiceTap(item["name"] as String),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _C.divider, width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      item["image"] as String,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(item["icon"] as String,
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item["name"] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.dark,
                      height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── POPULAR SERVICES ─────────────────────────────────────────────────────────
  Widget _buildPopularList() {
    final popular = [
      {
        "name": "Home Cleaning",
        "image": "assets/house cleaning.webp",
        "rating": "4.8",
        "reviews": "12K",
        "price": "₹499",
        "tag": "Top Rated"
      },
      {
        "name": "AC Service & Repair",
        "image": "assets/ac repair.webp",
        "rating": "4.7",
        "reviews": "8.5K",
        "price": "₹299",
        "tag": "Most Booked"
      },
      {
        "name": "Salon at Home",
        "image": "assets/salon.webp",
        "rating": "4.9",
        "reviews": "6K",
        "price": "₹199",
        "tag": "New"
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: popular.length,
      itemBuilder: (context, i) {
        final p = popular[i];
        return GestureDetector(
          onTap: () => _onPopularServiceTap(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.divider),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(18)),
                child: Image.asset(
                  p["image"]!,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: _C.cyanLight,
                    child: const Icon(Icons.home_repair_service_rounded,
                        color: _C.cyan1, size: 32),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(p["name"]!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _C.dark)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.cyanLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p["tag"]!,
                              style: const TextStyle(
                                  color: _C.cyan2,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFA000), size: 14),
                        const SizedBox(width: 3),
                        Text(p["rating"]!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _C.dark)),
                        Text("  (${p['reviews']!} reviews)",
                            style:
                                const TextStyle(fontSize: 11, color: _C.muted)),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Starting ${p['price']!}",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: _C.cyan2)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _C.cyan1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Book Now",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Location deny reason ─────────────────────────────────────────────────────
enum _LocationDenyReason {
  serviceDisabled,
  permissionDenied,
  permissionPermanent,
}
