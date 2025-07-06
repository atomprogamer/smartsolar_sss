import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to add sample services to Firestore
/// Run this script once to populate the services collection
/// This script checks for existing services to avoid duplication
void main() async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Sample services
    final List<Map<String, dynamic>> services = [
      {
        'serviceType': 'installation',
        'description': 'Professional installation of solar panels, inverters, and batteries. Our expert technicians ensure proper setup and optimal performance of your solar system.',
        'price': 25000.0,
        'duration': '1-2 days',
        'imageUrls': ['assets/images/services/installation.png', 'assets/icons/installation_icon.png'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'serviceType': 'maintenance',
        'description': 'Regular maintenance service to keep your solar system running efficiently. Includes inspection, cleaning, and performance optimization.',
        'price': 5000.0,
        'duration': '3-4 hours',
        'imageUrls': ['assets/images/services/maintenance.png', 'assets/icons/maintenance_icon.png'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'serviceType': 'repair',
        'description': 'Repair service for damaged or malfunctioning solar systems. Our technicians diagnose and fix issues with panels, inverters, batteries, and wiring.',
        'price': 7500.0,
        'duration': 'Varies',
        'imageUrls': ['assets/images/services/repair.png', 'assets/icons/repair_icon.png'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'serviceType': 'consultation',
        'description': 'Expert consultation on solar system design, energy requirements, and cost estimation. Get personalized advice for your specific needs.',
        'price': 2000.0,
        'duration': '1 hour',
        'imageUrls': ['assets/images/services/consultation.png', 'assets/icons/consultation_icon.png'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'serviceType': 'cleaning',
        'description': 'Professional cleaning of solar panels to remove dust, dirt, and debris that can reduce efficiency. Recommended every 3-6 months.',
        'price': 3000.0,
        'duration': '2-3 hours',
        'imageUrls': ['assets/images/services/cleaning.png', 'assets/icons/cleaning_icon.png'],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    // Add services to Firestore with duplication check
    for (final service in services) {
      try {
        // Check if service with this type already exists
        final existingServices = await firestore
            .collection('services')
            .where('serviceType', isEqualTo: service['serviceType'])
            .get();

        if (existingServices.docs.isEmpty) {
          // Service doesn't exist, add it
          await firestore.collection('services').add(service);
          print('Added service: ${service['serviceType']}');
        } else {
          // Service exists, update it if needed
          final docId = existingServices.docs.first.id;

          // Update the existing service with new data but keep the same ID
          service['updatedAt'] = Timestamp.now(); // Update the timestamp
          await firestore.collection('services').doc(docId).update(service);
          print('Updated existing service: ${service['serviceType']}');
        }
      } catch (e) {
        print('Error processing service ${service['serviceType']}: $e');
      }
    }

    print('Sample services processed successfully!');
  } catch (e) {
    print('Error in main execution: $e');
  }
}
