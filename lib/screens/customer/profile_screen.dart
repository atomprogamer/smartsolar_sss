import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/auth_provider.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../models/user_model.dart';

/// ProfileScreen displays user profile information and provides options
/// to edit profile, view orders, and access other user-specific features
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh user data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                AppRoutes.navigateAndRemoveUntil(context, AppRoutes.welcome);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : user == null
              ? Center(child: Text('User not found'))
              : RefreshIndicator(
                  onRefresh: _refreshUserData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        Center(
                          child: Column(
                            children: [
                              // Profile picture
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                backgroundImage: user.profilePicture != null
                                    ? NetworkImage(user.profilePicture!)
                                    : null,
                                child: user.profilePicture == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppTheme.primaryColor,
                                      )
                                    : null,
                              ),
                              SizedBox(height: 16),

                              // User name
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 4),

                              // User type badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  user.userType.toString().split('.').last.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Profile actions
                        _buildActionCard(
                          context,
                          title: 'Edit Profile',
                          icon: Icons.edit,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.editProfile);
                          },
                        ),

                        _buildActionCard(
                          context,
                          title: 'My Orders',
                          icon: Icons.shopping_bag,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.orderHistory);
                          },
                        ),

                        _buildActionCard(
                          context,
                          title: 'Maintenance Requests',
                          icon: Icons.build,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.maintenanceRequest);
                          },
                        ),

                        _buildActionCard(
                          context,
                          title: 'Solar System Estimator',
                          icon: Icons.calculate,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.costEstimator);
                          },
                        ),

                        _buildActionCard(
                          context,
                          title: 'Knowledge Base',
                          icon: Icons.menu_book,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.knowledgeBase);
                          },
                        ),

                        _buildActionCard(
                          context,
                          title: 'Expert Consultation',
                          icon: Icons.support_agent,
                          onTap: () {
                            AppRoutes.navigateTo(context, AppRoutes.consultation);
                          },
                        ),

                        SizedBox(height: 24),

                        // User information section
                        Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 16),

                        _buildInfoItem(
                          icon: Icons.email,
                          title: 'Email',
                          value: user.email,
                        ),

                        _buildInfoItem(
                          icon: Icons.phone,
                          title: 'Phone',
                          value: user.phoneNumber,
                        ),

                        if (user.address != null)
                          _buildInfoItem(
                            icon: Icons.home,
                            title: 'Address',
                            value: user.address!,
                          ),

                        if (user.city != null)
                          _buildInfoItem(
                            icon: Icons.location_city,
                            title: 'City',
                            value: user.city!,
                          ),

                        SizedBox(height: 24),

                        // Account information
                        Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 16),

                        _buildInfoItem(
                          icon: Icons.verified_user,
                          title: 'Account Status',
                          value: user.approvalStatus.toString().split('.').last.toUpperCase(),
                          valueColor: user.isApproved ? Colors.green : Colors.orange,
                        ),

                        _buildInfoItem(
                          icon: Icons.calendar_today,
                          title: 'Member Since',
                          value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
