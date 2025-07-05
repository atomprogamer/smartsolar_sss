import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for user types
enum UserType { customer, vendor, admin, expert, technician }

/// Enum for user approval status
enum ApprovalStatus { pending, approved, rejected }

/// User model class based on the class diagram
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profilePicture;
  final String? address;
  final UserType userType;
  final ApprovalStatus approvalStatus;
  final String? preferredSystemConfig;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GeoPoint? location;
  final String? city;
  final String? specialization;

  /// Constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePicture,
    this.address,
    required this.userType,
    required this.approvalStatus,
    this.preferredSystemConfig,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.city,
    this.specialization,
  });

  /// Create an empty user
  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      phoneNumber: '',
      userType: UserType.customer,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      specialization: null, // <-- Add this line
    );
  }

  /// Create a user from a Firebase document snapshot
  factory UserModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return UserModel(
      uid: snapshot.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profilePicture: data['profilePicture'],
      address: data['address'],
      userType: _getUserTypeFromString(data['userType'] ?? 'customer'),
      approvalStatus: _getApprovalStatusFromString(
        data['approvalStatus'] ?? 'pending',
      ),
      preferredSystemConfig: data['preferredSystemConfig'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?,
      city: data['city'],
      specialization: data['specialization'],
    );
  }

  /// Convert user to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'address': address,
      'userType': userType.toString().split('.').last,
      'approvalStatus': approvalStatus.toString().split('.').last,
      'preferredSystemConfig': preferredSystemConfig,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'location': location,
      'city': city,
      'specialization': specialization,
    };
  }

  /// Create a copy of the user with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? address,
    UserType? userType,
    ApprovalStatus? approvalStatus,
    String? preferredSystemConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
    GeoPoint? location,
    String? city,
    String? specialization,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      preferredSystemConfig:
          preferredSystemConfig ?? this.preferredSystemConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      city: city ?? this.city,
      specialization: specialization ?? this.specialization,
    );
  }

  /// Helper method to convert string to UserType enum
  static UserType _getUserTypeFromString(String userType) {
    switch (userType) {
      case 'customer':
        return UserType.customer;
      case 'vendor':
        return UserType.vendor;
      case 'admin':
        return UserType.admin;
      case 'expert':
        return UserType.expert;
      case 'technician':
        return UserType.technician;
      default:
        return UserType.customer;
    }
  }

  /// Helper method to convert string to ApprovalStatus enum
  static ApprovalStatus _getApprovalStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  /// Check if the user is approved
  bool get isApproved => approvalStatus == ApprovalStatus.approved;

  /// Check if the user is a customer
  bool get isCustomer => userType == UserType.customer;

  /// Check if the user is a vendor
  bool get isVendor => userType == UserType.vendor;

  /// Check if the user is an admin
  bool get isAdmin => userType == UserType.admin;

  /// Check if the user is an expert
  bool get isExpert => userType == UserType.expert;

  /// Check if the user is a technician
  bool get isTechnician => userType == UserType.technician;

  /// Check if the user is a staff member (admin, expert, or technician)
  bool get isStaff => isAdmin || isExpert || isTechnician;
}
