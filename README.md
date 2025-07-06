# Smart Solar Solution App

A Flutter application for solar system installation, maintenance, and related services.

## Features

- User authentication and management
- Product catalog and ordering
- Service booking and management
- Admin dashboard for managing users, products, and services
- Expert consultation and knowledge base

## Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (Firestore, Authentication)
4. Run the app with `flutter run`

## Populating Sample Data

### Services

To populate the Firestore database with sample services, run the following command:

```bash
dart lib/scripts/add_sample_services.dart
```

This will add the following services to the database:

1. **Installation** - Professional installation of solar panels, inverters, and batteries
2. **Maintenance** - Regular maintenance service to keep your solar system running efficiently
3. **Repair** - Repair service for damaged or malfunctioning solar systems
4. **Consultation** - Expert consultation on solar system design and requirements
5. **Cleaning** - Professional cleaning of solar panels to maintain efficiency

## Service Management

The app provides a comprehensive service management system:

- **Admin Dashboard**: View and manage all services
- **Service Catalog**: Display available services to customers
- **Service Booking**: Allow customers to book services
- **Service Tracking**: Track the status of service bookings

## Implementation Details

- Services are stored in Firestore with the following fields:
  - serviceType: Type of service (installation, maintenance, repair, etc.)
  - description: Detailed description of the service
  - price: Cost of the service in PKR
  - duration: Estimated time to complete the service
  - imageUrls: Array of image URLs for the service
  - createdAt: Timestamp when the service was created
  - updatedAt: Timestamp when the service was last updated

- Service types are represented with appropriate icons:
  - Installation: build icon
  - Maintenance: handyman icon
  - Repair: home_repair_service icon
  - Consultation: support_agent icon
  - Cleaning: cleaning_services icon