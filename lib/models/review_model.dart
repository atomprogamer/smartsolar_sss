import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model class based on the class diagram
class ReviewModel {
  final String id;
  final String userId;
  final String? productId;
  final String? serviceId;
  final int rating;
  final String comment;
  final DateTime reviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userImage;
  
  /// Constructor
  ReviewModel({
    required this.id,
    required this.userId,
    this.productId,
    this.serviceId,
    required this.rating,
    required this.comment,
    required this.reviewDate,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userImage,
  });
  
  /// Create an empty review
  factory ReviewModel.empty() {
    return ReviewModel(
      id: '',
      userId: '',
      rating: 0,
      comment: '',
      reviewDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a review from a Firebase document snapshot
  factory ReviewModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return ReviewModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      productId: data['productId'],
      serviceId: data['serviceId'],
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      reviewDate: (data['reviewDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userName: data['userName'],
      userImage: data['userImage'],
    );
  }
  
  /// Convert review to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'serviceId': serviceId,
      'rating': rating,
      'comment': comment,
      'reviewDate': Timestamp.fromDate(reviewDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userName': userName,
      'userImage': userImage,
    };
  }
  
  /// Create a copy of the review with updated fields
  ReviewModel copyWith({
    String? id,
    String? userId,
    String? productId,
    String? serviceId,
    int? rating,
    String? comment,
    DateTime? reviewDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userImage,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      serviceId: serviceId ?? this.serviceId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      reviewDate: reviewDate ?? this.reviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
    );
  }
  
  /// Check if the review is for a product
  bool get isProductReview => productId != null && productId!.isNotEmpty;
  
  /// Check if the review is for a service
  bool get isServiceReview => serviceId != null && serviceId!.isNotEmpty;
  
  /// Get formatted review date
  String get formattedReviewDate {
    final day = reviewDate.day.toString().padLeft(2, '0');
    final month = reviewDate.month.toString().padLeft(2, '0');
    final year = reviewDate.year.toString();
    return '$day-$month-$year';
  }
  
  /// Get star rating as a string of star emojis
  String get starRating {
    String stars = '';
    for (int i = 0; i < rating; i++) {
      stars += '⭐';
    }
    return stars;
  }
  
  /// Get display name (uses userName if available, otherwise "Anonymous")
  String get displayName {
    if (userName != null && userName!.isNotEmpty) {
      return userName!;
    }
    return 'Anonymous';
  }
  
  /// Get user avatar (uses userImage if available, otherwise a placeholder)
  String get userAvatar {
    if (userImage != null && userImage!.isNotEmpty) {
      return userImage!;
    }
    return 'https://via.placeholder.com/50x50?text=User';
  }
}

/// Maintenance request model class
class MaintenanceRequestModel {
  final String id;
  final String userId;
  final String? serviceId;
  final String issueDescription;
  final DateTime requestDate;
  final String status;
  final String? assignedTechnicianId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeoPoint? location;
  final String? address;
  final String? city;
  final String? technicianNotes;
  final DateTime? scheduledDate;
  final List<String>? imageUrls;
  
  /// Constructor
  MaintenanceRequestModel({
    required this.id,
    required this.userId,
    this.serviceId,
    required this.issueDescription,
    required this.requestDate,
    required this.status,
    this.assignedTechnicianId,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.address,
    this.city,
    this.technicianNotes,
    this.scheduledDate,
    this.imageUrls,
  });
  
  /// Create an empty maintenance request
  factory MaintenanceRequestModel.empty() {
    return MaintenanceRequestModel(
      id: '',
      userId: '',
      issueDescription: '',
      requestDate: DateTime.now(),
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a maintenance request from a Firebase document snapshot
  factory MaintenanceRequestModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return MaintenanceRequestModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      serviceId: data['serviceId'],
      issueDescription: data['issueDescription'] ?? '',
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      assignedTechnicianId: data['assignedTechnicianId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?,
      address: data['address'],
      city: data['city'],
      technicianNotes: data['technicianNotes'],
      scheduledDate: data['scheduledDate'] != null 
          ? (data['scheduledDate'] as Timestamp).toDate() 
          : null,
      imageUrls: data['imageUrls'] != null 
          ? List<String>.from(data['imageUrls']) 
          : null,
    );
  }
  
  /// Convert maintenance request to a map for Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'serviceId': serviceId,
      'issueDescription': issueDescription,
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status,
      'assignedTechnicianId': assignedTechnicianId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'address': address,
      'city': city,
      'technicianNotes': technicianNotes,
      'imageUrls': imageUrls,
    };
    
    if (scheduledDate != null) {
      map['scheduledDate'] = Timestamp.fromDate(scheduledDate!);
    }
    
    return map;
  }
  
  /// Create a copy of the maintenance request with updated fields
  MaintenanceRequestModel copyWith({
    String? id,
    String? userId,
    String? serviceId,
    String? issueDescription,
    DateTime? requestDate,
    String? status,
    String? assignedTechnicianId,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    String? address,
    String? city,
    String? technicianNotes,
    DateTime? scheduledDate,
    List<String>? imageUrls,
  }) {
    return MaintenanceRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      issueDescription: issueDescription ?? this.issueDescription,
      requestDate: requestDate ?? this.requestDate,
      status: status ?? this.status,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
  
  /// Check if the maintenance request is pending
  bool get isPending => status.toLowerCase() == 'pending';
  
  /// Check if the maintenance request is assigned
  bool get isAssigned => status.toLowerCase() == 'assigned';
  
  /// Check if the maintenance request is in progress
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  
  /// Check if the maintenance request is completed
  bool get isCompleted => status.toLowerCase() == 'completed';
  
  /// Check if the maintenance request is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  
  /// Get formatted request date
  String get formattedRequestDate {
    final day = requestDate.day.toString().padLeft(2, '0');
    final month = requestDate.month.toString().padLeft(2, '0');
    final year = requestDate.year.toString();
    return '$day-$month-$year';
  }
  
  /// Get formatted scheduled date if available
  String get formattedScheduledDate {
    if (scheduledDate == null) {
      return 'Not scheduled';
    }
    
    final day = scheduledDate!.day.toString().padLeft(2, '0');
    final month = scheduledDate!.month.toString().padLeft(2, '0');
    final year = scheduledDate!.year.toString();
    return '$day-$month-$year';
  }
  
  /// Get status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}