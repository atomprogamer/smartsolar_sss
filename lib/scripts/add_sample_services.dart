import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to add sample services to Firestore
/// Run this script once to populate the services collection
void main() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Sample services
  final List<Map<String, dynamic>> services = [
    {
      'serviceType': 'installation',
      'description': 'Professional installation of solar panels, inverters, and batteries. Our expert technicians ensure proper setup and optimal performance of your solar system.',
      'price': 25000.0,
      'duration': '1-2 days',
      'imageUrls': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'serviceType': 'maintenance',
      'description': 'Regular maintenance service to keep your solar system running efficiently. Includes inspection, cleaning, and performance optimization.',
      'price': 5000.0,
      'duration': '3-4 hours',
      'imageUrls': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'serviceType': 'repair',
      'description': 'Repair service for damaged or malfunctioning solar systems. Our technicians diagnose and fix issues with panels, inverters, batteries, and wiring.',
      'price': 7500.0,
      'duration': 'Varies',
      'imageUrls': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'serviceType': 'consultation',
      'description': 'Expert consultation on solar system design, energy requirements, and cost estimation. Get personalized advice for your specific needs.',
      'price': 2000.0,
      'duration': '1 hour',
      'imageUrls': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
    {
      'serviceType': 'cleaning',
      'description': 'Professional cleaning of solar panels to remove dust, dirt, and debris that can reduce efficiency. Recommended every 3-6 months.',
      'price': 3000.0,
      'duration': '2-3 hours',
      'imageUrls': [],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    },
  ];
  
  // Add services to Firestore
  for (final service in services) {
    try {
      await firestore.collection('services').add(service);
      print('Added service: ${service['serviceType']}');
    } catch (e) {
      print('Error adding service ${service['serviceType']}: $e');
    }
  }
  
  print('Sample services added successfully!');
}