# 📮 IntelliPost

> Smart document scanner for Indian Post letters — digitize, extract, and organize postal correspondence with ease.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **📷 Document Scanning** — Capture letters using your device camera with auto-edge detection
- **🖼️ Gallery Import** — Import existing images from your photo library
- **🔍 Text Extraction** — AI-powered OCR to extract sender/recipient details, addresses, and pincodes
- **📊 Scan History** — Browse and search through all your digitized letters
- **🌙 Dark Theme** — Beautiful dark UI designed for comfortable viewing

## 📱 Screenshots

| Login | Home | Scan | History |
|:-----:|:----:|:----:|:-------:|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Scan](screenshots/scan.png) | ![History](screenshots/history.png) |

## 🏗️ Architecture

This app follows the **MVVM (Model-View-ViewModel)** pattern with Provider for state management:

```
lib/
├── core/
│   ├── theme/          # App colors, typography, theme
│   └── widgets/        # Reusable UI components
├── features/
│   ├── auth/           # Login screen & authentication
│   ├── home/           # Home dashboard
│   ├── scan/           # Camera, preview, scan flow
│   └── history/        # Scan history & details
├── models/             # Data models (User, Scan)
├── services/           # API & Storage services
└── main.dart           # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Android Emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/intellipost.git
   cd intellipost/app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Test Credentials

The app uses mock API services for development. Use any valid inputs:

| Field | Example |
|-------|---------|
| Name | `Test User` |
| Phone | `9876543210` |
| Email | `test@example.com` |

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider |
| Local Storage | Hive |
| Camera | camera, image_picker |
| HTTP Client | http |
| Unique IDs | uuid |

## 📦 Dependencies

```yaml
dependencies:
  provider: ^6.1.2
  camera: ^0.11.0+2
  image_picker: ^1.1.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  http: ^1.2.2
  uuid: ^4.5.1
  intl: ^0.19.0
```

## 🔧 Configuration

### Android Permissions

Camera and storage permissions are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### Switching to Real API

Replace `MockApiService` with `RealApiService` in `lib/main.dart`:

```dart
// Change from:
final apiService = MockApiService();

// To:
final apiService = RealApiService(baseUrl: 'https://your-api.com');
```

## 🎨 Design

- **Color Scheme**: Purple/Violet primary with dark theme
- **Typography**: Clean, modern sans-serif
- **Inspiration**: Adobe Scan, modern form designs

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

<p align="center">
  Made with ❤️ for Indian Post
</p>
