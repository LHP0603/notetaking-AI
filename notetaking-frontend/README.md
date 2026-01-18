# Voicely Frontend

A clean architecture Flutter application for voice communication technology.

## Features

- 🎯 Clean Architecture implementation
- 🔐 Authentication (Login/Signup)
- 🚀 Landing page with feature highlights
- 🎨 Modern UI with custom theme
- 📱 Responsive design
- 🔧 State management with BLoC
- 🌐 HTTP client with Dio
- 📦 Dependency injection with GetIt

## Project Structure

```
lib/
├── core/                          # Core functionality
│   ├── constants/                 # App constants
│   ├── errors/                    # Error handling
│   ├── network/                   # Network configuration
│   ├── routes/                    # App routing
│   ├── theme/                     # App theme
│   └── utils/                     # Utility functions
├── features/                      # Feature modules
│   ├── auth/                      # Authentication feature
│   │   ├── data/                  # Data layer
│   │   │   ├── datasources/       # Local & remote data sources
│   │   │   ├── models/            # Data models
│   │   │   └── repositories/      # Repository implementations
│   │   ├── domain/                # Domain layer
│   │   │   ├── entities/          # Business entities
│   │   │   ├── repositories/      # Repository interfaces
│   │   │   └── usecases/          # Business logic
│   │   └── presentation/          # Presentation layer
│   │       ├── bloc/              # State management
│   │       ├── pages/             # UI pages
│   │       └── widgets/           # Reusable widgets
│   └── landing/                   # Landing page feature
│       └── presentation/
│           ├── pages/
│           └── widgets/
├── injection_container/           # Dependency injection
└── main.dart                      # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.7.2)
- Dart SDK
- Android Studio / VS Code
- Android/iOS emulator or physical device

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd voicely_fe
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the application:

```bash
flutter run
```

## Architecture

This project follows **Clean Architecture** principles:

### Data Layer

- **Data Sources**: Handle API calls and local storage
- **Models**: Data transfer objects with JSON serialization
- **Repositories**: Implement domain repository interfaces

### Domain Layer

- **Entities**: Core business objects
- **Repositories**: Abstract interfaces for data access
- **Use Cases**: Encapsulate business logic

### Presentation Layer

- **BLoC**: State management and business logic coordination
- **Pages**: UI screens
- **Widgets**: Reusable UI components

## Key Dependencies

- `flutter_bloc`: State management
- `get_it`: Dependency injection
- `dio`: HTTP client
- `go_router`: Navigation
- `shared_preferences`: Local storage
- `dartz`: Functional programming utilities
- `equatable`: Value equality

## API Integration

The app is configured to work with a backend API. Update the base URL in:

```
lib/core/constants/app_constants.dart
```

## Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Use meaningful commit messages
4. Follow Dart/Flutter style guidelines

## License

This project is licensed under the MIT License.
