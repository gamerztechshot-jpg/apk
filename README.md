# Karmasu - Spiritual App

A Flutter application for spiritual practices including Pooja Sadhna, Naam japa, and Astrologer Booking.

## Features

- **Authentication**: Login/Signup with Supabase
- **Pooja Sadhna**: Puja booking and sadhna tracking
- **नाम जप**: Digital Likhit Jaap with streak tracking
- **Astrologer Booking**: Certified astrologer consultation

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Android Emulator or Physical Device

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd karmasu
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - The app is already configured with your Supabase credentials
   - Supabase URL: `https://dsoaiypfqxdqbvjsxikd.supabase.co`
   - Configuration is in `lib/core/config/supabase_config.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart    # Supabase configuration
│   └── services/
│       └── auth_service.dart       # Authentication service
├── features/
│   ├── auth/
│   │   └── login.dart              # Login/Signup screen
│   └── home/
│       └── home.dart               # Home screen with feature grid
├── routes.dart                     # App routing
└── main.dart                       # App entry point
```

## Current Implementation

- ✅ **Authentication System**: Complete login/signup with Supabase
- ✅ **Home Screen**: Feature grid with navigation placeholders
- ✅ **Form Validation**: Input validation for all fields
- ✅ **UI Design**: Modern, spiritual-themed design with gradients

## Next Steps

1. **Install Dependencies**: Run `flutter pub get`
2. **Test Authentication**: Test login/signup functionality
3. **Build Core Features**: Implement the three main modules
4. **Database Setup**: Create necessary tables in Supabase

## Dependencies

- `supabase_flutter`: For backend authentication and database
- `flutter`: Core Flutter framework

## Support

For any issues or questions, please check the Flutter documentation or Supabase documentation.
