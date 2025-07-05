import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for knowledge base article categories
enum ArticleCategory {
  solarBasics,
  installation,
  maintenance,
  troubleshooting,
  productGuides,
  energySaving,
}

/// KnowledgeBase model class based on the class diagram
class KnowledgeBaseModel {
  final String id;
  final String title;
  final String content;
  final ArticleCategory category;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;
  final List<String> tags;
  final bool featured;
  
  /// Constructor
  KnowledgeBaseModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
    this.tags = const [],
    this.featured = false,
  });
  
  /// Create an empty knowledge base article
  factory KnowledgeBaseModel.empty() {
    return KnowledgeBaseModel(
      id: '',
      title: '',
      content: '',
      category: ArticleCategory.solarBasics,
      author: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a knowledge base article from a Firebase document snapshot
  factory KnowledgeBaseModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return KnowledgeBaseModel(
      id: snapshot.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: _getCategoryFromString(data['category'] ?? 'solarBasics'),
      author: data['author'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      featured: data['featured'] ?? false,
    );
  }
  
  /// Convert knowledge base article to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category.toString().split('.').last,
      'author': author,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrls': imageUrls,
      'tags': tags,
      'featured': featured,
    };
  }
  
  /// Create a copy of the knowledge base article with updated fields
  KnowledgeBaseModel copyWith({
    String? id,
    String? title,
    String? content,
    ArticleCategory? category,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    List<String>? tags,
    bool? featured,
  }) {
    return KnowledgeBaseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      featured: featured ?? this.featured,
    );
  }
  
  /// Helper method to convert string to ArticleCategory enum
  static ArticleCategory _getCategoryFromString(String category) {
    switch (category) {
      case 'solarBasics':
        return ArticleCategory.solarBasics;
      case 'installation':
        return ArticleCategory.installation;
      case 'maintenance':
        return ArticleCategory.maintenance;
      case 'troubleshooting':
        return ArticleCategory.troubleshooting;
      case 'productGuides':
        return ArticleCategory.productGuides;
      case 'energySaving':
        return ArticleCategory.energySaving;
      default:
        return ArticleCategory.solarBasics;
    }
  }
  
  /// Get category name as a string
  String get categoryName {
    switch (category) {
      case ArticleCategory.solarBasics:
        return 'Solar Basics';
      case ArticleCategory.installation:
        return 'Installation';
      case ArticleCategory.maintenance:
        return 'Maintenance';
      case ArticleCategory.troubleshooting:
        return 'Troubleshooting';
      case ArticleCategory.productGuides:
        return 'Product Guides';
      case ArticleCategory.energySaving:
        return 'Energy Saving';
    }
  }
  
  /// Get the main image URL or a placeholder if no images are available
  String get mainImageUrl {
    if (imageUrls.isNotEmpty) {
      return imageUrls[0];
    }
    return 'https://via.placeholder.com/300x200?text=Solar+Knowledge';
  }
  
  /// Get a short excerpt from the content
  String get excerpt {
    if (content.length <= 150) {
      return content;
    }
    return '${content.substring(0, 150)}...';
  }
  
  /// Get formatted creation date
  String get formattedCreatedAt {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    return '$day-$month-$year';
  }
}

/// Consultation model class
class ConsultationModel {
  final String id;
  final String userId;
  final String expertId;
  final DateTime consultationDate;
  final String duration;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? topic;
  final String? userQuestions;
  final String? expertResponse;
  
  /// Constructor
  ConsultationModel({
    required this.id,
    required this.userId,
    required this.expertId,
    required this.consultationDate,
    required this.duration,
    this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.topic,
    this.userQuestions,
    this.expertResponse,
  });
  
  /// Create an empty consultation
  factory ConsultationModel.empty() {
    return ConsultationModel(
      id: '',
      userId: '',
      expertId: '',
      consultationDate: DateTime.now().add(const Duration(days: 1)),
      duration: '30 minutes',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a consultation from a Firebase document snapshot
  factory ConsultationModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    
    return ConsultationModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      expertId: data['expertId'] ?? '',
      consultationDate: (data['consultationDate'] as Timestamp).toDate(),
      duration: data['duration'] ?? '30 minutes',
      notes: data['notes'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      topic: data['topic'],
      userQuestions: data['userQuestions'],
      expertResponse: data['expertResponse'],
    );
  }
  
  /// Convert consultation to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'expertId': expertId,
      'consultationDate': Timestamp.fromDate(consultationDate),
      'duration': duration,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'topic': topic,
      'userQuestions': userQuestions,
      'expertResponse': expertResponse,
    };
  }
  
  /// Create a copy of the consultation with updated fields
  ConsultationModel copyWith({
    String? id,
    String? userId,
    String? expertId,
    DateTime? consultationDate,
    String? duration,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? topic,
    String? userQuestions,
    String? expertResponse,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      expertId: expertId ?? this.expertId,
      consultationDate: consultationDate ?? this.consultationDate,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      topic: topic ?? this.topic,
      userQuestions: userQuestions ?? this.userQuestions,
      expertResponse: expertResponse ?? this.expertResponse,
    );
  }
  
  /// Check if the consultation is pending
  bool get isPending => status.toLowerCase() == 'pending';
  
  /// Check if the consultation is confirmed
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  
  /// Check if the consultation is completed
  bool get isCompleted => status.toLowerCase() == 'completed';
  
  /// Check if the consultation is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  
  /// Get formatted consultation date
  String get formattedConsultationDate {
    final day = consultationDate.day.toString().padLeft(2, '0');
    final month = consultationDate.month.toString().padLeft(2, '0');
    final year = consultationDate.year.toString();
    return '$day-$month-$year';
  }
  
  /// Get formatted consultation time
  String get formattedConsultationTime {
    final hour = consultationDate.hour.toString().padLeft(2, '0');
    final minute = consultationDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}