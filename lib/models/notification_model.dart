import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for notification types
enum NotificationType {
  order,
  service,
  maintenance,
  payment,
  approval,
  promotion,
  system,
}

/// Notification model class based on the class diagram
class NotificationModel {
  final String id;
  final String userId;
  final String message;
  final NotificationType type;
  final DateTime sentDate;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? relatedId;
  final String? title;
  final String? imageUrl;
  
  /// Constructor
  NotificationModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.type,
    required this.sentDate,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.relatedId,
    this.title,
    this.imageUrl,
  });
  
  /// Create an empty notification
  factory NotificationModel.empty() {
    return NotificationModel(
      id: '',
      userId: '',
      message: '',
      type: NotificationType.system,
      sentDate: DateTime.now(),
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a notification from a Firebase document snapshot
  factory NotificationModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      type: _getNotificationTypeFromString(data['type'] ?? 'system'),
      sentDate: (data['sentDate'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      relatedId: data['relatedId'],
      title: data['title'],
      imageUrl: data['imageUrl'],
    );
  }
  
  /// Convert notification to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'type': type.toString().split('.').last,
      'sentDate': Timestamp.fromDate(sentDate),
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'relatedId': relatedId,
      'title': title,
      'imageUrl': imageUrl,
    };
  }
  
  /// Create a copy of the notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? message,
    NotificationType? type,
    DateTime? sentDate,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? relatedId,
    String? title,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      sentDate: sentDate ?? this.sentDate,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      relatedId: relatedId ?? this.relatedId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  
  /// Helper method to convert string to NotificationType enum
  static NotificationType _getNotificationTypeFromString(String type) {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'service':
        return NotificationType.service;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'payment':
        return NotificationType.payment;
      case 'approval':
        return NotificationType.approval;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
  
  /// Get formatted sent date
  String get formattedSentDate {
    final day = sentDate.day.toString().padLeft(2, '0');
    final month = sentDate.month.toString().padLeft(2, '0');
    final year = sentDate.year.toString();
    return '$day-$month-$year';
  }
  
  /// Get formatted sent time
  String get formattedSentTime {
    final hour = sentDate.hour.toString().padLeft(2, '0');
    final minute = sentDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  /// Get notification type icon
  String get typeIcon {
    switch (type) {
      case NotificationType.order:
        return 'assets/icons/order_notification.png';
      case NotificationType.service:
        return 'assets/icons/service_notification.png';
      case NotificationType.maintenance:
        return 'assets/icons/maintenance_notification.png';
      case NotificationType.payment:
        return 'assets/icons/payment_notification.png';
      case NotificationType.approval:
        return 'assets/icons/approval_notification.png';
      case NotificationType.promotion:
        return 'assets/icons/promotion_notification.png';
      case NotificationType.system:
        return 'assets/icons/system_notification.png';
    }
  }
  
  /// Get notification type name
  String get typeName {
    switch (type) {
      case NotificationType.order:
        return 'Order';
      case NotificationType.service:
        return 'Service';
      case NotificationType.maintenance:
        return 'Maintenance';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.system:
        return 'System';
    }
  }
  
  /// Get notification title (uses title if available, otherwise type name)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    return typeName;
  }
  
  /// Get time ago text (e.g., "2 hours ago", "5 minutes ago")
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(sentDate);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Expert model class based on the class diagram
class ExpertModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String specialization;
  final String availability;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePicture;
  final String? bio;
  final List<String>? expertiseAreas;
  
  /// Constructor
  ExpertModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.specialization,
    required this.availability,
    required this.createdAt,
    required this.updatedAt,
    this.profilePicture,
    this.bio,
    this.expertiseAreas,
  });
  
  /// Create an empty expert
  factory ExpertModel.empty() {
    return ExpertModel(
      id: '',
      name: '',
      email: '',
      phoneNumber: '',
      specialization: '',
      availability: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create an expert from a Firebase document snapshot
  factory ExpertModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return ExpertModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      specialization: data['specialization'] ?? '',
      availability: data['availability'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      profilePicture: data['profilePicture'],
      bio: data['bio'],
      expertiseAreas: data['expertiseAreas'] != null 
          ? List<String>.from(data['expertiseAreas']) 
          : null,
    );
  }
  
  /// Convert expert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'specialization': specialization,
      'availability': availability,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'profilePicture': profilePicture,
      'bio': bio,
      'expertiseAreas': expertiseAreas,
    };
  }
  
  /// Create a copy of the expert with updated fields
  ExpertModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? specialization,
    String? availability,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePicture,
    String? bio,
    List<String>? expertiseAreas,
  }) {
    return ExpertModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialization: specialization ?? this.specialization,
      availability: availability ?? this.availability,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      expertiseAreas: expertiseAreas ?? this.expertiseAreas,
    );
  }
  
  /// Get profile picture URL or a placeholder if not available
  String get profilePictureUrl {
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      return profilePicture!;
    }
    return 'https://via.placeholder.com/150x150?text=Expert';
  }
  
  /// Get expertise areas as a comma-separated string
  String get expertiseAreasText {
    if (expertiseAreas == null || expertiseAreas!.isEmpty) {
      return specialization;
    }
    return expertiseAreas!.join(', ');
  }
}