# IntelliPost

> Smart document scanner for India Post letters — digitize, extract, and organize postal correspondence with ease.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Document Scanning** — Capture letters using your device camera
- **Gallery Import** — Import existing images from your photo library
- **Text Extraction** — AI-powered OCR to extract sender/recipient details, addresses, and pincodes
- **Scan History** — Browse, filter, and sort through all your digitized letters
- **Dark Theme** — Polished dark UI designed for comfortable viewing

## Architecture

The app follows **MVVM** with Provider for state management.

```mermaid
graph TD
    A[main.dart] --> B[core/]
    A --> C[features/]
    A --> D[models/]
    A --> E[services/]

    B --> B1[theme/]
    B --> B2[widgets/]
    B --> B3[config.dart]

    C --> C1[auth/]
    C --> C2[home/]
    C --> C3[scan/]
    C --> C4[history/]

    C1 --> V1[view/]
    C1 --> VM1[viewmodel/]
    C2 --> V2[view/]
    C2 --> VM2[viewmodel/]
    C3 --> V3[view/]
    C3 --> VM3[viewmodel/]
    C4 --> V4[view/]
    C4 --> VM4[viewmodel/]

    E --> E1[API Service]
    E --> E2[Auth Service]
    E --> E3[Storage Service]
```

### Scan Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant API

    User->>App: Capture / Import image
    App->>API: Request presigned upload URL
    API-->>App: Upload URL + file key
    App->>API: Upload image to presigned URL
    App->>API: Process uploaded image (OCR)
    API-->>App: Extracted text & metadata
    App->>App: Save to local history
    App-->>User: Display extracted details
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Android emulator or physical device

### Setup

```bash
git clone https://github.com/yourusername/intellipost.git
cd intellipost
flutter pub get
flutter run
```

### Configuration

The API base URL is configured in `lib/core/config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://44.222.223.134';
}
```

Update this to point to your backend instance.

### Android Permissions

Camera and storage permissions are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider (MVVM) |
| Local Storage | Hive |
| Camera | camera, image\_picker |
| HTTP Client | http |

## Project Structure

```
lib/
├── core/
│   ├── config.dart          # API and app configuration
│   ├── theme/               # Colors, text styles, theme data
│   └── widgets/             # Shared UI components
├── features/
│   ├── auth/                # Login & registration
│   ├── home/                # Home screen & navigation
│   ├── scan/                # Camera, preview, scan options
│   └── history/             # Scan history & detail views
├── models/                  # UserModel, ScanModel (Hive)
├── services/                # API, Auth, and Storage services
└── main.dart                # App entry point & routing
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
