# devent — Event Discovery & Ticket Booking

> A Flutter mobile application for discovering events, booking tickets, and validating entry using QR codes.

## 📸 Screenshots

Application screenshots are available inside the repository:

👉 **Screenshots Folder:**  
## 📸 Screenshots

<p align="center">
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166393_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166394_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166395_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166396_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166397_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166398_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166401_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166400_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166399_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166401_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166404_y.jpg" width="220"/>
  <img src="https://github.com/fallofffff/devent/blob/main/screenshoots/photo_5814354506186166403_y.jpg" width="220"/>
  
  
</p>
## Table of Contents

- Overview
- Features
- Tech Stack
- Project Structure
- Prerequisites
- Firebase Setup
- Local Setup
- Running the App
- Firestore Security Rules
- State Management
- Theme
- Dependencies
- Firestore Data Model

---

## Overview

**devent** is a Flutter-based Event Discovery & Ticket Booking platform developed as a university CSE final project.

The application solves common issues in event management by creating a centralized system where users can discover events, book tickets, manage booking history, and validate entries using QR technology.

The platform addresses several real-world problems:

- Fragmented event promotions across social media
- Unreliable manual ticket booking systems
- Lack of booking history tracking
- Weak ticket authentication and entry validation

Users can browse events, reserve tickets instantly, receive QR-based tickets, and organizers can validate attendee access through QR scanning.

---

## Features

| Feature | Description |
|----------|-------------|
| Event Listing & Search | Browse available events and filter by title |
| Event Details | View event description, organizer, date, venue, and ticket availability |
| Ticket Booking | Reserve tickets with real-time inventory updates |
| QR Ticket Generation | Generate unique QR codes for every booking |
| QR Validation | Organizer QR scanner validates attendee entry |
| Booking History | Track previous and upcoming reservations |
| Push Notifications | Event reminders using FCM and local notifications |
| Authentication | Firebase email/password login and registration |
| Dark Mode | System-aware black & white UI theme |

---

## Tech Stack

| Layer | Technology |
|-------|-------------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging + Local Notifications |
| QR Generation | qr_flutter |
| QR Scanning | mobile_scanner |
| Code Generation | build_runner + riverpod_generator |

---

## Project Structure

```plaintext
lib/
├── core/
│   ├── firebase/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── events/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── booking/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── notifications/
│
├── main.dart
└── firebase_options.dart
```

---

## Prerequisites

Install the following before setup:

- Flutter SDK `>=3.12.0`
- Dart SDK
- Firebase CLI
- FlutterFire CLI
- Android Studio / Xcode
- Firebase Project

---

## Firebase Setup

### 1. Create Firebase Project

Go to:

https://console.firebase.google.com

Create a new Firebase project.

### 2. Enable Services

Enable:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Cloud Messaging

### 3. Configure FlutterFire

Run:

```bash
flutterfire configure --project=<your-project-id>
```

This generates:

```plaintext
lib/firebase_options.dart
```

### 4. Deploy Rules

```bash
firebase deploy --only firestore:rules
```

---

## Local Setup

Clone the repository:

```bash
git clone https://github.com/fallofffff/devent.git
cd devent
```

Install dependencies:

```bash
flutter pub get
```

Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Configure Firebase if needed:

```bash
flutterfire configure
```

Run application:

```bash
flutter run
```

---

## Running the App

Debug mode:

```bash
flutter run
```

Specific device:

```bash
flutter run -d <device-id>
```

List devices:

```bash
flutter devices
```

Release APK:

```bash
flutter build apk --release
```

iOS Release:

```bash
flutter build ipa --release
```

> Push notifications require a physical device on iOS.

---

## Firestore Security Rules

Access model:

### Events Collection
- Authenticated users → Read access
- Admin → Write access

### Bookings Collection
- Users → Create and read their own bookings
- Organizer validator → Update validation status

### Users Collection
- Users can only access their own documents.

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

---

## State Management

The application uses **Riverpod** across the entire architecture.

Patterns used:

- `StreamProvider`
- `FutureProvider`
- `AsyncNotifierProvider`

Benefits:

- Reactive UI updates
- Separated business logic
- Minimal widget complexity
- Scalable architecture

---

## Theme

The UI follows a strict **black & white design system** with full dark mode support.

| Token | Light | Dark |
|-------|-------|------|
| Background | #FFFFFF | #0A0A0A |
| Surface | #F5F5F5 | #1A1A1A |
| Primary | #000000 | #FFFFFF |
| Text | #1A1A1A | #F0F0F0 |

Supports:

- System Theme
- Manual Override
- Dark Mode

---

## Dependencies

### Runtime Packages

- flutter_riverpod
- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- firebase_messaging
- flutter_local_notifications
- permission_handler
- qr_flutter
- mobile_scanner
- timezone
- intl

### Development Packages

- build_runner
- riverpod_generator
- flutter_lints

---

## Firestore Data Model

```plaintext
users/{uid}
  name
  email
  createdAt

events/{eventId}
  title
  description
  date
  location
  organizerName
  imageUrl
  totalTickets
  availableTickets
  createdAt

bookings/{bookingId}
  userId
  eventId
  eventTitle
  eventDate
  bookedAt
  qrData
  isValidated
```

---

## Team

Developed as a **University CSE Final Project**.

Project: **Problem 2 — Event Discovery & Ticket Booking System**
