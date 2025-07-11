# DL Star | A Live Streaming APP

A Flutter application built with Clean Architecture, BLoC pattern, and modern development practices.

## Architecture

This project follows Clean Architecture principles with the following structure:

### 📁 Project Structure

```
lib/
├── core/                      # Core functionality
│   ├── constants/            # App constants
│   ├── errors/              # Error handling
│   ├── network/             # Network utilities
│   ├── theme/               # UI theme
│   └── utils/               # Utility functions
├── features/                # Feature modules
│   └── home/               # Home feature
│       ├── data/           # Data layer
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/         # Domain layer
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/   # Presentation layer
│           ├── bloc/
│           ├── pages/
│           └── widgets/
├── injection/              # Dependency injection
└── routing/               # Navigation
```

### 🏗️ Architecture Layers

1. **Domain Layer** - Business logic and entities
2. **Data Layer** - Data sources and repositories
3. **Presentation Layer** - UI and state management

### 🛠️ Technologies Used

- **State Management**: BLoC Pattern with flutter_bloc
- **Dependency Injection**: GetIt with Injectable
- **Navigation**: Go Router
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Functional Programming**: Dartz for Either type
- **Code Generation**: build_runner, json_serializable

## Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Dart SDK

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code:
   ```bash
   flutter packages pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Development Commands

- **Generate code**: `dart run build_runner build`
- **Watch for changes**: `dart run build_runner watch`
- **Clean generated files**: `dart run build_runner clean`

## Features

- ✅ Clean Architecture
- ✅ BLoC State Management
- ✅ Dependency Injection
- ✅ Modern UI with Material 3
- ✅ Dark/Light Theme Support
- ✅ Navigation with Go Router
- ✅ Error Handling
- ✅ Local Data Persistence

## Contributing

1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License.
