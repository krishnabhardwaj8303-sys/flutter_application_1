# Ajoomi — Local Service Booking App

Ajoomi is a cross-platform mobile application that connects users with **verified local service providers**, enabling fast, transparent, and reliable service bookings — with live tracking from booking to arrival.

---

## Table of Contents

- [About the Project](#about-the-project)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [How It Works](#how-it-works)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Supported Platforms](#supported-platforms)
- [Roadmap](#roadmap)
- [Contact](#contact)

---

## About the Project

Ajoomi aims to simplify the local services industry by connecting users with **background-verified professionals** in their area — plumbers, electricians, cleaners, and more — through a single, easy-to-use mobile app.

Once a service is booked, users can track their assigned provider in real time, similar to a ride-hailing experience, with an expected arrival window of around 10 minutes depending on availability in the area.

---

## Key Features

- **Instant Service Booking** — Book a nearby verified provider in just a few taps
- **Fast Arrival** — Providers typically arrive within 10 minutes, subject to area availability
- **Verified Professionals** — All service providers undergo identity and background verification
- **Live Tracking** — Real-time location tracking from booking confirmation to arrival
- **Push Notifications** — Updates for booking confirmation, provider en route, arrival, and completion
- **Ratings & Reviews** — Clients can rate and review providers after each service
- **Secure Payments** — Support for online payments and cash on service
- **Booking History** — View past and upcoming bookings in one place
- **Cross-Platform Support** — Built with Flutter for a consistent experience across Android, iOS, and desktop/web

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Platforms | Android, iOS, Web, Windows, macOS, Linux |
| Web Integration | HTML |
| Native Build Support | C++, CMake, Swift, C |

---

## How It Works

1. **Sign Up / Login** — User creates an account within the app
2. **Select a Service** — Choose the required service category (plumbing, electrical, cleaning, etc.)
3. **Auto-Match** — The nearest verified provider is automatically assigned
4. **Live Tracking** — Track the provider's location in real time as they head to the service location
5. **Service Completion** — Once the service is complete, the user makes payment and leaves a rating

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev) installed and configured
- A code editor such as Android Studio, VS Code, or IntelliJ
- An emulator or physical device for testing (Android/iOS)

### Running the App

1. Clone this repository to your local machine.
2. Run `flutter pub get` to install project dependencies.
3. Connect a device or start an emulator.
4. Run `flutter run` to launch the app.

---

## Project Structure

```
ajoomi/
├── android/          # Android platform-specific code
├── ios/               # iOS platform-specific code
├── linux/              # Linux platform-specific code
├── macos/                # macOS platform-specific code
├── windows/                # Windows platform-specific code
├── web/                      # Web platform-specific code
├── assets/                     # Images, icons, and other static assets
├── lib/                          # Core Dart application source code
├── test/                           # Automated tests
├── pubspec.yaml                      # Project dependencies and configuration
├── analysis_options.yaml               # Dart/Flutter linting rules
└── README.md
```

---

## Supported Platforms

Ajoomi is built with Flutter, allowing it to run across multiple platforms from a single codebase:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

---

## Roadmap

- [ ] In-app chat between user and service provider
- [ ] AI-based provider recommendation and matching
- [ ] Subscription plans for recurring/regular services
- [ ] Multi-language support
- [ ] Provider-side companion app for managing jobs

---

## Contact

**Maintainer:** Krishna Bhardwaj

For questions or feedback related to Ajoomi, please reach out through the project's GitHub repository.
