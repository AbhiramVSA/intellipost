# IntelliPost

> Smart document scanner for India Post letters — digitize, extract, and organize postal correspondence with ease.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Document Scanning** — Capture letters using your device camera with auto-edge detection
- **Gallery Import** — Import existing images from your photo library
- **Text Extraction** — AI-powered OCR to extract sender/recipient details, addresses, and pincodes
- **Scan History** — Browse and search through all your digitized letters
- **Dark Theme** — Beautiful dark UI designed for comfortable viewing

## Screenshots

| Login | Home | Scan | History |
|:-----:|:----:|:----:|:-------:|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Scan](screenshots/scan.png) | ![History](screenshots/history.png) |

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

    C --> C1[auth/]
    C --> C2[home/]
    C --> C3[scan/]
    C --> C4[history/]

    C1 --> V1[views/]
    C1 --> VM1[viewmodels/]
    C2 --> V2[views/]
    C2 --> VM2[viewmodels/]
    C3 --> V3[views/]
    C3 --> VM3[viewmodels/]
    C4 --> V4[views/]
    C4 --> VM4[viewmodels/]

    D --> D1[User]
    D --> D2[Scan]

    E --> E1[API Service]
    E --> E2[Storage Service]
```

### Scan Flow

```mermaid
sequenceDiagram
    participant User
    participant App
    participant API

    User->>App: Capture / Import image
    App->>API: Request presigned upload URL
    API-->>App: Upload URL
    App->>API: Upload image to URL
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

### Installation

```bash
git clone https://github.com/yourusername/intellipost.git
cd intellipost/app
flutter pub get
flutter run
```

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider |
| Local Storage | Hive |
| Camera | camera, image\_picker |
| HTTP Client | http |

## Configuration

### Android Permissions

Camera and storage permissions are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes
4. Push to the branch
5. Open a Pull Request
