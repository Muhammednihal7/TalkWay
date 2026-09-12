# Talkway

A 1-to-1 audio and video calling application built with Flutter, Firebase, and Agora.

Talkway allows users to register, manage contacts, make real-time audio/video calls, and view their call history. Real-time communication is powered by Agora, while Firebase is used for authentication and cloud data management.

## Features

-  User registration and login
-  Home dashboard
-  Contacts management
-  1-to-1 audio calling
-  1-to-1 video calling
-  Call history
-  1-to-1 real-time chat
-  Profile picture upload
-  Firebase authentication and cloud database
-  Real-time communication using Agora

## Tech Stack

### Frontend
- Flutter
- Dart
- Riverpod

### Backend & Services
- Firebase Authentication
- Cloud Firestore
- Firebase Realtime Database
- Agora RTC Engine

### Other Packages
- `permission_handler`
- `connectivity_plus`
- `cached_network_image`
- `google_fonts`
- `intl`
- `uuid`

## Project Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── models/
│
├── providers/
│
├── screens/
│   ├── auth/
│   ├── call/
│   ├── contacts/
│   ├── history/
│   ├── home/
│   └── profile/
│
├── firebase_options.dart
└── main.dart