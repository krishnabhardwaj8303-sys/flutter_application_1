// ─────────────────────────────────────────────────────────────────────────────
//  ADD THESE 2 CALLS in book_service.dart  (_sendRequest method)
//  Add them RIGHT AFTER the FirebaseFirestore 'requests' .add() call
// ─────────────────────────────────────────────────────────────────────────────

// In book_service.dart — inside _sendRequest(), after docRef is created:
/*
  final docRef = await FirebaseFirestore.instance.collection('requests').add({ ... });

  // ✅ ADD THIS — saves notification to user's subcollection
  await saveNotification(
    uid:   uid,
    type:  'Booking',
    title: 'Booking Confirmed ✅',
    body:  '${widget.category} · ${_selectedSubCategory ?? widget.subCategory} has been booked. We are finding a worker near you.',
  );

  // ✅ If online payment was done, also add a Payment notification
  if (_paymentMethod == 'ONLINE') {
    await saveNotification(
      uid:   uid,
      type:  'Payment',
      title: 'Payment Successful 💳',
      body:  'Payment of ₹${_total.toStringAsFixed(0)} received for ${widget.category}.',
    );
  }
*/

// ─────────────────────────────────────────────────────────────────────────────
//  ADD THESE 2 CALLS in schedule_booking_screen.dart  (_sendRequest method)
//  Same pattern — after docRef is created
// ─────────────────────────────────────────────────────────────────────────────

/*
  final docRef = await FirebaseFirestore.instance.collection('requests').add({ ... });

  // ✅ ADD THIS
  await saveNotification(
    uid:   uid,
    type:  'Booking',
    title: 'Booking Scheduled 📅',
    body:  '$_selectedService · $_selectedSubCategory scheduled for $_selectedDate at $_selectedTimeSlot.',
  );

  if (_paymentMethod == 'ONLINE') {
    await saveNotification(
      uid:   uid,
      type:  'Payment',
      title: 'Payment Successful 💳',
      body:  'Payment of ₹${_total.toStringAsFixed(0)} received for $_selectedService.',
    );
  }
*/

// ─────────────────────────────────────────────────────────────────────────────
//  IMPORT LINE — add to top of book_service.dart and schedule_booking_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

// import 'notification_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FIRESTORE RULES — make sure this is allowed in Firebase Console
// ─────────────────────────────────────────────────────────────────────────────

/*
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/notifications/{notifId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
*/
