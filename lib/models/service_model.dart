import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for service types
enum ServiceType { installation, maintenance, repair, consultation, cleaning }

/// Service model class based on the class diagram
class ServiceModel {
  final String id;
  final String serviceType;
  final String description;
  final double price;
  final String duration;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Constructor
  ServiceModel({
    required this.id,
    required this.serviceType,
    required this.description,
    required this.price,
    required this.duration,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an empty service
  factory ServiceModel.empty() {
    return ServiceModel(
      id: '',
      serviceType: '',
      description: '',
      price: 0.0,
      duration: '',
      imageUrls: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a service from a Firebase document snapshot
  factory ServiceModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ServiceModel(
      id: snapshot.id,
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      duration: data['duration'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert service to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'serviceType': serviceType,
      'description': description,
      'price': price,
      'duration': duration,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of the service with updated fields
  ServiceModel copyWith({
    String? id,
    String? serviceType,
    String? description,
    double? price,
    String? duration,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted price in Pakistani Rupees (PKR)
  String get formattedPrice => 'PKR ${price.toStringAsFixed(2)}';

  /// Get the main image URL or a placeholder if no images are available
  String get mainImageUrl {
    if (imageUrls.isNotEmpty) {
      return imageUrls[0];
    }
    return 'assets/images/placeholder_service.png'; // Local asset placeholder
  }

  /// Get service type icon
  String get serviceTypeIcon {
    switch (serviceType.toLowerCase()) {
      case 'installation':
        return 'assets/icons/installation.png';
      case 'maintenance':
        return 'assets/icons/maintenance.png';
      case 'repair':
        return 'assets/icons/repair.png';
      case 'consultation':
        return 'assets/icons/consultation.png';
      case 'cleaning':
        return 'assets/icons/cleaning.png';
      default:
        return 'assets/icons/service.png';
    }
  }

  /// Get formatted duration
  String get formattedDuration {
    if (duration.isEmpty) {
      return 'Variable';
    }
    return duration;
  }
}

/// Service booking model class
class ServiceBookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime bookingDate;
  final DateTime scheduledDate;
  final String location;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeoPoint? locationCoordinates;
  final String? city;
  final String? assignedTechnicianId;
  final String? serviceType; // Add this line

  /// Constructor
  ServiceBookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.bookingDate,
    required this.scheduledDate,
    required this.location,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.locationCoordinates,
    this.city,
    this.assignedTechnicianId,
    this.serviceType, // Add this line
  });

  /// Create an empty service booking
  factory ServiceBookingModel.empty() {
    return ServiceBookingModel(
      id: '',
      userId: '',
      serviceId: '',
      bookingDate: DateTime.now(),
      scheduledDate: DateTime.now().add(const Duration(days: 1)),
      location: '',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a service booking from a Firebase document snapshot
  factory ServiceBookingModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return ServiceBookingModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      locationCoordinates: data['locationCoordinates'] as GeoPoint?,
      city: data['city'],
      assignedTechnicianId: data['assignedTechnicianId'],
      serviceType: data['serviceType'] as String?, // Add this line
    );
  }

  /// Convert service booking to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceId': serviceId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'location': location,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'locationCoordinates': locationCoordinates,
      'city': city,
      'assignedTechnicianId': assignedTechnicianId,
      'serviceType': serviceType, // Add this line
    };
  }

  /// Create a copy of the service booking with updated fields
  ServiceBookingModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? bookingDate,
    DateTime? scheduledDate,
    String? location,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? locationCoordinates,
    String? city,
    String? assignedTechnicianId,
    String? serviceType, // Add this line
  }) {
    return ServiceBookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      bookingDate: bookingDate ?? this.bookingDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      city: city ?? this.city,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      serviceType: serviceType ?? this.serviceType, // Add this line
    );
  }

  /// Check if the service booking is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if the service booking is confirmed
  bool get isConfirmed => status.toLowerCase() == 'confirmed';

  /// Check if the service booking is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if the service booking is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Get formatted scheduled date
  String get formattedScheduledDate {
    final day = scheduledDate.day.toString().padLeft(2, '0');
    final month = scheduledDate.month.toString().padLeft(2, '0');
    final year = scheduledDate.year.toString();
    return '$day-$month-$year';
  }

  /// Get formatted scheduled time
  String get formattedScheduledTime {
    final hour = scheduledDate.hour.toString().padLeft(2, '0');
    final minute = scheduledDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
