# Flutter ToDo App

A Flutter application for managing tasks and to-do items with data persistence.

## Features

- ✅ Add new to-do items
- ✅ Mark tasks as completed
- ✅ Delete tasks
- 💾 Data persistence using SharedPreferences
- 🆔 Unique ID generation using UUID

## Getting Started

This project is a Flutter application for learning and practicing Flutter development.

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio or VS Code

### Dependencies

- `shared_preferences: ^2.2.2` - For data persistence
- `uuid: ^4.2.1` - For generating unique identifiers

### Installation

1. Clone the repository:
```bash
git clone https://github.com/knx14/flutter-todoapp.git
```

2. Navigate to the project directory:
```bash
cd flutter-todoapp
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart              # Main application entry point
└── models/
    └── todo_item.dart     # TodoItem model class
```

## Learning Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

## License

This project is for educational purposes.
