import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

/// ManageUsersScreen displays a list of users and allows admin to manage them
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: _buildUserManagementTab(),
    );
  }

  Widget _buildUserManagementTab() {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'All Users'),
              Tab(text: 'Customers'),
              Tab(text: 'Staff'),
              Tab(text: 'Pending'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(userProvider.users),
                _buildUsersList(
                  userProvider.users.where((u) => u.isCustomer).toList(),
                ),
                _buildUsersList(
                  userProvider.users.where((u) => u.isStaff).toList(),
                ),
                _buildUsersList(userProvider.pendingUsers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    if (users.isEmpty) {
      return Center(child: Text('No users found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUserTypeColor(
                user.userType,
              ).withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(color: _getUserTypeColor(user.userType)),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(
              '${user.email} • ${_getUserTypeString(user.userType)}',
            ),
            trailing:
                user.approvalStatus == ApprovalStatus.pending
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveUser(user),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectUser(user),
                        ),
                      ],
                    )
                    : _getStatusBadge(user.approvalStatus),
            onTap: () => _showUserDetailsDialog(user),
          ),
        );
      },
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.purple;
      case UserType.expert:
        return Colors.blue;
      case UserType.technician:
        return Colors.orange;
      case UserType.customer:
        return Colors.green;
      case UserType.vendor:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.expert:
        return 'Expert';
      case UserType.technician:
        return 'Technician';
      case UserType.customer:
        return 'Customer';
      case UserType.vendor:
        return 'Vendor';
      default:
        return 'Unknown';
    }
  }

  Widget _getStatusBadge(ApprovalStatus status) {
    Color color;
    String text;

    switch (status) {
      case ApprovalStatus.approved:
        color = Colors.green;
        text = 'APPROVED';
        break;
      case ApprovalStatus.pending:
        color = Colors.orange;
        text = 'PENDING';
        break;
      case ApprovalStatus.rejected:
        color = Colors.red;
        text = 'REJECTED';
        break;
      default:
        color = Colors.grey;
        text = 'UNKNOWN';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _approveUser(UserModel user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Approve User'),
            content: Text('Are you sure you want to approve ${user.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.approveUser(user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User approved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _rejectUser(UserModel user) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reject User'),
            content: Text('Are you sure you want to reject ${user.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await userProvider.rejectUser(user.uid);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User rejected'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Reject'),
              ),
            ],
          ),
    );
  }

  void _showUserDetailsDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('User Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserDetailItem('Name', user.name),
                  _buildUserDetailItem('Email', user.email),
                  _buildUserDetailItem('Phone', user.phoneNumber),
                  if (user.address != null)
                    _buildUserDetailItem('Address', user.address!),
                  if (user.city != null)
                    _buildUserDetailItem('City', user.city!),
                  _buildUserDetailItem(
                    'User Type',
                    user.userType.toString().split('.').last,
                  ),
                  _buildUserDetailItem(
                    'Status',
                    user.approvalStatus.toString().split('.').last,
                  ),
                  _buildUserDetailItem(
                    'Created At',
                    _formatDate(user.createdAt),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildUserDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }
}
