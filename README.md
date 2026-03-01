# Project Title: On-Demand Service Marketplace Mobile App

## Overview

This project is a full-stack mobile application connecting users who need services with service providers. It will be available on both Android and iOS.

## Features

### Core Features:
- Separate sign-up/login for Users and Service Providers.
- Service Provider profiles: name, service type, hourly rate, location, availability, description.
- User ability to browse providers, send service requests, and book services.
- User rating (1-5 stars) and written comments for providers after service completion.

### Database Structure:
- User accounts database.
- Provider accounts database.
- Ratings and comments database.

### Additional Features:
- Booking system with status updates (pending, accepted, completed).
- Optional in-app chat between users and providers.
- Push notifications for booking updates.
- Admin dashboard for moderation and user management.
- Optional payment integration (Stripe or PayPal).
- Favorites list for users.
- Service history for users.
- Search and filter functionality for providers.

## Technology Stack

- **Cross-Platform Framework:** React Native
- **Backend Framework:** Node.js with Express
- **Database:** PostgreSQL
- **Authentication:** (To be decided - e.g., JWT)
- **Payment Integration:** (To be decided - Stripe or PayPal if implemented)

## Project Structure

The project is divided into two main parts:

- `mobile-app/`: Contains the React Native frontend application.
- `server/`: Contains the Node.js with Express backend application.

## Getting Started

(Instructions to be added later)

## Contributing

(Guidelines for contributors to be added later)

## License

(License information to be added later) 



how to run the backend 
1- cd /Users/ameralnajdawi/Desktop/JO_service/server
2_ npm run dev

to run the frontend 
1- cd /Users/ameralnajdawi/Desktop/JO_service/jo_service_app
2- flutter run -d chrome
