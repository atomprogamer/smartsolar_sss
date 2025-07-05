import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import '../../providers/auth_provider.dart';
import '../../utils/routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../models/user_model.dart';

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  _StaffRegisterScreenState createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  UserType _selectedRole = UserType.expert; // Default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.registerStaff(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        userType: _selectedRole,
        specialization: _specializationController.text.trim(),
      );

      if (success && mounted) {
        // Show success message and navigate to approval pending screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful! Please wait for admin approval.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to approval pending screen
        AppRoutes.navigateAndRemoveUntil(context, AppRoutes.approvalPending);
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For Google sign-in, we need to handle the role selection differently
    // since we can't set the role before authentication
    // We'll show a dialog to select the role after Google sign-in

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.signInWithGoogle();

      if (success && mounted) {
        // Navigate based on user type
        if (authProvider.isStaff) {
          if (authProvider.isAdmin) {
            AppRoutes.navigateAndRemoveUntil(context, AppRoutes.adminDashboard);
          } else if (authProvider.isExpert) {
            AppRoutes.navigateAndRemoveUntil(
              context,
              AppRoutes.expertDashboard,
            );
          } else if (authProvider.isTechnician) {
            AppRoutes.navigateAndRemoveUntil(
              context,
              AppRoutes.technicianDashboard,
            );
          }
        } else {
          // If not a staff member, sign out and show error
          await authProvider.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This Google account is not registered as staff. Please use email registration.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // If the error message contains "pending approval", navigate to approval pending screen
      if (e.toString().contains('pending approval')) {
        AppRoutes.navigateAndRemoveUntil(context, AppRoutes.approvalPending);
      }
      // Other errors are already handled in the provider
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Registration'),
        elevation: 0,
        backgroundColor: AppTheme.secondaryColor,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.secondaryColor, Colors.white],
            stops: [0.2, 0.2],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),

                  // Register card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff Registration',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          'Register as a staff member (Admin, Solar Expert, or Technician)',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(height: 30),

                        // Register form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              ),

                              SizedBox(height: 15),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validators.validateEmail,
                              ),

                              SizedBox(height: 15),

                              // Phone field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validators.validatePhone,
                              ),

                              SizedBox(height: 20),

                              // Role selection
                              Text(
                                'Select your role:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),

                              SizedBox(height: 10),

                              // Radio buttons for role selection
                              Column(
                                children: [
                                  // Admin radio
                                  RadioListTile<UserType>(
                                    title: Text('Administrator'),
                                    subtitle: Text(
                                      'Manage users, products, and services',
                                    ),
                                    value: UserType.admin,
                                    groupValue: _selectedRole,
                                    activeColor: AppTheme.secondaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value!;
                                      });
                                    },
                                  ),

                                  // Expert radio
                                  RadioListTile<UserType>(
                                    title: Text('Solar Expert'),
                                    subtitle: Text(
                                      'Provide consultations and knowledge base articles',
                                    ),
                                    value: UserType.expert,
                                    groupValue: _selectedRole,
                                    activeColor: AppTheme.secondaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value!;
                                      });
                                    },
                                  ),

                                  // Technician radio
                                  RadioListTile<UserType>(
                                    title: Text('Technician'),
                                    subtitle: Text(
                                      'Handle installations and maintenance requests',
                                    ),
                                    value: UserType.technician,
                                    groupValue: _selectedRole,
                                    activeColor: AppTheme.secondaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRole = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(height: 15),

                              // Specialization field (for experts and technicians)
                              if (_selectedRole == UserType.expert ||
                                  _selectedRole == UserType.technician)
                                TextFormField(
                                  controller: _specializationController,
                                  decoration: InputDecoration(
                                    labelText: 'Specialization',
                                    prefixIcon: Icon(Icons.work),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    hintText:
                                        _selectedRole == UserType.expert
                                            ? 'e.g., Solar Panel Design, Energy Efficiency'
                                            : 'e.g., Installation, Maintenance, Repair',
                                  ),
                                  validator:
                                      _selectedRole == UserType.expert ||
                                              _selectedRole ==
                                                  UserType.technician
                                          ? Validators.validateSpecialization
                                          : null,
                                ),

                              SizedBox(height: 15),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: Validators.validatePassword,
                              ),

                              SizedBox(height: 15),

                              // Confirm Password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        Validators.validateConfirmPassword(
                                          value,
                                          _passwordController.text,
                                        ),
                              ),

                              SizedBox(height: 15),

                              // Terms and conditions
                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: AppTheme.secondaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    // Navigate to terms of service
                                                  },
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppTheme.secondaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = () {
                                                    // Navigate to privacy policy
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),

                              // Error message
                              if (authProvider.error != null)
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authProvider.error!,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              SizedBox(height: 20),

                              // Register button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      authProvider.isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      authProvider.isLoading
                                          ? CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                          : Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // Or divider
                              Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text('OR'),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),

                              SizedBox(height: 20),

                              // Google register button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      authProvider.isLoading
                                          ? null
                                          : _registerWithGoogle,
                                  icon: Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: Colors.red,
                                  ),
                                  label: Text('Register with Google'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.secondaryColor,
                                    side: BorderSide(
                                      color: AppTheme.secondaryColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // Login link
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 16,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Already have a staff account? ',
                                    ),
                                    TextSpan(
                                      text: 'Login',
                                      style: TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              AppRoutes.navigateTo(
                                                context,
                                                AppRoutes.staffLogin,
                                              );
                                            },
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Note about approval
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info, color: Colors.blue),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Staff Account Approval',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'All staff accounts require approval from an administrator before they can be used. After registration, please wait for approval.',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
