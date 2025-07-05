import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

import '../../providers/auth_provider.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../models/user_model.dart';

/// EditProfileScreen allows users to update their profile information
/// including name, phone number, address, city, and profile picture
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  File? _imageFile;
  String? _currentProfilePicUrl;
  bool _isLoading = false;
  bool _imageUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
      _addressController.text = user.address ?? '';
      _cityController.text = user.city ?? '';
      _currentProfilePicUrl = user.profilePicture;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<String?> _uploadProfilePicture() async {
    if (_imageFile == null) return _currentProfilePicUrl;

    setState(() {
      _imageUploading = true;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});

      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _imageUploading = false;
        _errorMessage = 'Failed to upload image: $e';
      });
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Upload profile picture if changed
      final profilePictureUrl = await _uploadProfilePicture();

      // Update user profile
      final success = await Provider.of<AuthProvider>(context, listen: false).updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        profilePicture: profilePictureUrl,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to profile screen
        Navigator.pop(context);
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error updating profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Profile')),
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_currentProfilePicUrl != null
                            ? NetworkImage(_currentProfilePicUrl!)
                            : null) as ImageProvider?,
                    child: _imageUploading
                        ? CircularProgressIndicator()
                        : (_imageFile == null && _currentProfilePicUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: AppTheme.primaryColor,
                              )
                            : null),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 20,
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.validateName,
                enabled: !_isLoading,
              ),

              SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.validatePhone,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 16),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.validateAddress,
                enabled: !_isLoading,
                maxLines: 2,
              ),

              SizedBox(height: 16),

              // City field
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: Validators.validateCity,
                enabled: !_isLoading,
              ),

              SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Note about email
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email address cannot be changed. Contact support if you need to update your email.',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
