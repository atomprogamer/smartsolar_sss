import 'package:flutter/material.dart';
import '../utils/routes.dart';
import '../utils/theme.dart';

/// AppDrawer is a reusable drawer component that provides navigation
/// to all customer-related screens in the application
class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header with app logo and name
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.solar_power,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Smart Solar Solution',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Dashboard
            ListTile(
              leading: Icon(Icons.dashboard, color: AppTheme.primaryColor),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                AppRoutes.navigateTo(context, AppRoutes.customerDashboard);
              },
            ),
            
            // Products
            ListTile(
              leading: Icon(Icons.inventory_2, color: AppTheme.primaryColor),
              title: Text('Products'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.productCatalog);
              },
            ),
            
            // Services
            ListTile(
              leading: Icon(Icons.miscellaneous_services, color: AppTheme.primaryColor),
              title: Text('Services'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.serviceCatalog);
              },
            ),
            
            // Cart
            ListTile(
              leading: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
              title: Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.cart);
              },
            ),
            
            // Orders
            ListTile(
              leading: Icon(Icons.receipt_long, color: AppTheme.primaryColor),
              title: Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.orderHistory);
              },
            ),
            
            // Maintenance Requests
            ListTile(
              leading: Icon(Icons.build, color: AppTheme.primaryColor),
              title: Text('Maintenance Requests'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.maintenanceRequest);
              },
            ),
            
            // Cost Estimator
            ListTile(
              leading: Icon(Icons.calculate, color: AppTheme.primaryColor),
              title: Text('Cost Estimator'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.costEstimator);
              },
            ),
            
            // Knowledge Base
            ListTile(
              leading: Icon(Icons.menu_book, color: AppTheme.primaryColor),
              title: Text('Knowledge Base'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.knowledgeBase);
              },
            ),
            
            // Consultation
            ListTile(
              leading: Icon(Icons.support_agent, color: AppTheme.primaryColor),
              title: Text('Consultation'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.consultation);
              },
            ),
            
            Divider(),
            
            // Profile
            ListTile(
              leading: Icon(Icons.person, color: AppTheme.primaryColor),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.profile);
              },
            ),
            
            // Login/Logout
            ListTile(
              leading: Icon(Icons.login, color: AppTheme.primaryColor),
              title: Text('Login'),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.navigateTo(context, AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}