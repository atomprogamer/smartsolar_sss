import 'package:flutter/material.dart';

// Import screens
import '../screens/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/staff_login_screen.dart';
import '../screens/auth/staff_register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/approval_pending_screen.dart';

// Customer screens
import '../screens/customer/customer_dashboard_screen.dart';
import '../screens/customer/product_catalog_screen.dart';
import '../screens/customer/product_details_screen.dart';
import '../screens/customer/service_catalog_screen.dart';
import '../screens/customer/service_details_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/customer/order_details_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/edit_profile_screen.dart';
import '../screens/customer/maintenance_request_screen.dart';
import '../screens/customer/cost_estimator_screen.dart';
import '../screens/customer/knowledge_base_screen.dart';
import '../screens/customer/article_details_screen.dart';
import '../screens/customer/consultation_screen.dart';

// Admin screens
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/admin/manage_products_screen.dart';
import '../screens/admin/manage_services_screen.dart';
import '../screens/admin/manage_orders_screen.dart';
import '../screens/admin/manage_maintenance_screen.dart';
import '../screens/admin/manage_knowledge_screen.dart';

// Expert screens
import '../screens/expert/expert_dashboard_screen.dart';
import '../screens/expert/expert_consultations_screen.dart';
import '../screens/expert/expert_knowledge_screen.dart';

// Technician screens
import '../screens/technician/technician_dashboard_screen.dart';
import '../screens/technician/technician_tasks_screen.dart';

/// AppRoutes class defines all the navigation routes for the application
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String staffLogin = '/staff-login';
  static const String staffRegister = '/staff-register';
  static const String forgotPassword = '/forgot-password';
  static const String approvalPending = '/approval-pending';

  // Customer routes
  static const String customerDashboard = '/customer/dashboard';
  static const String productCatalog = '/customer/products';
  static const String productDetails = '/customer/product-details';
  static const String serviceCatalog = '/customer/services';
  static const String serviceDetails = '/customer/service-details';
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';
  static const String orderHistory = '/customer/orders';
  static const String orderDetails = '/customer/order-details';
  static const String profile = '/customer/profile';
  static const String editProfile = '/customer/edit-profile';
  static const String maintenanceRequest = '/customer/maintenance';
  static const String costEstimator = '/customer/cost-estimator';
  static const String knowledgeBase = '/customer/knowledge';
  static const String articleDetails = '/customer/article-details';
  static const String consultation = '/customer/consultation';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String manageUsers = '/admin/users';
  static const String manageProducts = '/admin/products';
  static const String manageServices = '/admin/services';
  static const String manageOrders = '/admin/orders';
  static const String manageMaintenance = '/admin/maintenance';
  static const String manageKnowledge = '/admin/knowledge';

  // Expert routes
  static const String expertDashboard = '/expert/dashboard';
  static const String expertConsultations = '/expert/consultations';
  static const String expertKnowledge = '/expert/knowledge';

  // Technician routes
  static const String technicianDashboard = '/technician/dashboard';
  static const String technicianTasks = '/technician/tasks';

  // Route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    welcome: (context) => WelcomeScreen(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    staffLogin: (context) => StaffLoginScreen(),
    staffRegister: (context) => StaffRegisterScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    approvalPending: (context) => ApprovalPendingScreen(),

    // Customer routes
    customerDashboard: (context) => CustomerDashboardScreen(),
    productCatalog: (context) => ProductCatalogScreen(),
    productDetails: (context) => ProductDetailsScreen(),
    serviceCatalog: (context) => ServiceCatalogScreen(),
    serviceDetails: (context) => ServiceDetailsScreen(),
    cart: (context) => CartScreen(),
    checkout: (context) => CheckoutScreen(),
    orderHistory: (context) => OrderHistoryScreen(),
    orderDetails: (context) => OrderDetailsScreen(),
    profile: (context) => ProfileScreen(),
    editProfile: (context) => EditProfileScreen(),
    maintenanceRequest: (context) => MaintenanceRequestScreen(),
    costEstimator: (context) => CostEstimatorScreen(),
    knowledgeBase: (context) => KnowledgeBaseScreen(),
    articleDetails: (context) => ArticleDetailsScreen(),
    consultation: (context) => ConsultationScreen(),

    // Admin routes
    adminDashboard: (context) => AdminDashboardScreen(),
    manageUsers: (context) => ManageUsersScreen(),
    manageProducts: (context) => ManageProductsScreen(),
    manageServices: (context) => ManageServicesScreen(),
    manageOrders: (context) => ManageOrdersScreen(),
    manageMaintenance: (context) => ManageMaintenanceScreen(),
    manageKnowledge: (context) => ManageKnowledgeScreen(),

    // Expert routes
    expertDashboard: (context) => ExpertDashboardScreen(),
    expertConsultations: (context) => ExpertConsultationsScreen(),
    expertKnowledge: (context) => ExpertKnowledgeScreen(),

    // Technician routes
    technicianDashboard: (context) => TechnicianDashboardScreen(),
    technicianTasks: (context) => TechnicianTasksScreen(),
  };

  /// Navigate to a named route
  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  static void navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and replace the current route
  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  /// Go back to the previous route
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
