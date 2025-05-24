# Health & Fitness Tracking App

A comprehensive health and fitness tracking application built with Flutter that helps users maintain their daily health goals through step tracking, water intake monitoring, and personalized health insights.

## Features

### 1. Step Tracking
- Automatic step counting throughout the day
- Customizable daily step goals
- Real-time progress tracking
- Visual progress indicators

### 2. Water Intake Monitoring
- Daily water intake tracking
- Customizable goals based on gender
- Hourly reminders
- Progress visualization

### 3. Streak System
- Daily streak tracking for consistent health habits
- Combined goals achievement tracking
- Visual streak indicators
- Motivational notifications

### 4. Smart Features
- "Ask Helly" - AI-powered health assistant
- Meal scanning for nutrition information
- Health and fitness news updates
- Personalized user profiles

## Technical Features

- Built with Flutter for cross-platform compatibility
- Firebase integration for real-time data synchronization
- Local notifications for reminders
- Pedometer integration for accurate step counting
- Clean and modern UI design

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone [your-repository-url]
```

2. Navigate to project directory:
```bash
cd final-one
```

3. Install dependencies:
```bash
flutter pub get
```

4. Configure Firebase:
- Create a new Firebase project
- Add your `google-services.json` to `/android/app/`
- Update Firebase configuration in `lib/firebase_options.dart`

5. Run the app:
```bash
flutter run
```

## Environment Setup

### Required Dependencies
Check `pubspec.yaml` for all dependencies. Key packages include:
- firebase_core
- firebase_auth
- cloud_firestore
- pedometer
- flutter_local_notifications

### Platform Configuration
The app is configured for:
- Android
- iOS
- Web (partial support)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent framework
- Firebase for backend services
- All contributors who helped with the project

## Contact

For any queries or suggestions, please open an issue in the repository.

---
Built with ❤️ using Flutter
