import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;

  const ServiceDetailScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    // 🔥 Dummy workers (later Firebase + location)
    final providers = [
      {"name": "Rahul", "rating": "4.8", "price": "₹299", "distance": "1.2 km"},
      {"name": "Amit", "rating": "4.5", "price": "₹249", "distance": "2.0 km"},
      {
        "name": "Suresh",
        "rating": "4.7",
        "price": "₹199",
        "distance": "0.8 km"
      },
      {"name": "Ravi", "rating": "4.6", "price": "₹279", "distance": "1.5 km"},
      {"name": "Rahul", "rating": "4.8", "price": "₹299", "distance": "1.2 km"},
      {"name": "Amit", "rating": "4.5", "price": "₹249", "distance": "2.0 km"},
      {
        "name": "Suresh",
        "rating": "4.7",
        "price": "₹199",
        "distance": "0.8 km"
      },
      {"name": "Ravi", "rating": "4.6", "price": "₹279", "distance": "1.5 km"},
      {"name": "Rahul", "rating": "4.8", "price": "₹299", "distance": "1.2 km"},
      {"name": "Amit", "rating": "4.5", "price": "₹249", "distance": "2.0 km"},
      {
        "name": "Suresh",
        "rating": "4.7",
        "price": "₹199",
        "distance": "0.8 km"
      },
      {"name": "Ravi", "rating": "4.6", "price": "₹279", "distance": "1.5 km"},
      {"name": "Rahul", "rating": "4.8", "price": "₹299", "distance": "1.2 km"},
      {"name": "Amit", "rating": "4.5", "price": "₹249", "distance": "2.0 km"},
      {
        "name": "Suresh",
        "rating": "4.7",
        "price": "₹199",
        "distance": "0.8 km"
      },
      {"name": "Ravi", "rating": "4.6", "price": "₹279", "distance": "1.5 km"},
      {"name": "Rahul", "rating": "4.8", "price": "₹299", "distance": "1.2 km"},
      {"name": "Amit", "rating": "4.5", "price": "₹249", "distance": "2.0 km"},
      {
        "name": "Suresh",
        "rating": "4.7",
        "price": "₹199",
        "distance": "0.8 km"
      },
      {"name": "Ravi", "rating": "4.6", "price": "₹279", "distance": "1.5 km"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("$serviceName Workers"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 HEADER TEXT
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Available Workers Near You",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 👥 LIST
          Expanded(
            child: ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                return providerCard(context, providers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 👤 WORKER CARD (UPGRADED UI)
  Widget providerCard(BuildContext context, Map provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          // 👤 PROFILE
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),

          const SizedBox(width: 15),

          // 📄 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text("⭐ ${provider["rating"]}"),
                    const SizedBox(width: 10),
                    Text("📍 ${provider["distance"]}"),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  provider["price"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // 🚀 REQUEST BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // 👉 NEXT STEP: go to searching screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Request sent to ${provider["name"]}"),
                ),
              );
            },
            child: const Text("Request"),
          ),
        ],
      ),
    );
  }
}
