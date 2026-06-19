import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────
class _C {
  static const cyan = Color(0xFF00BCD4);
  static const bg = Color(0xFFF7FAFA);
  static const dark = Color(0xFF0F172A);
}

// ─────────────────────────────────────────────────────────────
// SIMPLE LIVE TRACKING SCREEN
// ONLY:
// ✅ Live Worker Tracking
// ✅ Worker Phone Number
// ✅ Google Map
// ─────────────────────────────────────────────────────────────
class LiveTrackingScreen extends StatefulWidget {
  final String requestId;
  final String workerName;
  final String workerPhone;

  const LiveTrackingScreen({
    super.key,
    required this.requestId,
    required this.workerName,
    required this.workerPhone,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription? _requestSub;

  LatLng? _workerLatLng;

  final Set<Marker> _markers = {};

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _listenWorkerLocation();
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  // FIRESTORE LIVE LOCATION LISTENER
  // ───────────────────────────────────────────────────────────
  void _listenWorkerLocation() {
    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();

      if (data == null) return;

      final lat = (data['workerLat'] as num?)?.toDouble();
      final lng = (data['workerLng'] as num?)?.toDouble();

      if (lat == null || lng == null) return;

      final newPosition = LatLng(lat, lng);

      setState(() {
        _workerLatLng = newPosition;

        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId('worker'),
              position: newPosition,
              infoWindow: InfoWindow(title: widget.workerName),
            ),
          );
      });

      // Move camera live
      if (_mapReady && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      }
    });
  }

  // ───────────────────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,

      // ───────────────────────────────────────────────────────
      // APP BAR
      // ───────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _C.dark),
        title: const Text(
          'Live Tracking',
          style: TextStyle(
            color: _C.dark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ───────────────────────────────────────────────────────
      // BODY
      // ───────────────────────────────────────────────────────
      body: Stack(
        children: [
          // ───────────────────────────────────────────────────
          // GOOGLE MAP
          // ───────────────────────────────────────────────────
          Positioned.fill(
            child: _workerLatLng == null
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      setState(() => _mapReady = true);
                    },
                    initialCameraPosition: CameraPosition(
                      target: _workerLatLng!,
                      zoom: 16,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
          ),

          // ───────────────────────────────────────────────────
          // WORKER INFO CARD
          // ───────────────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: _C.cyan,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Worker Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _C.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workerPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Live Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _C.cyan,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
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
