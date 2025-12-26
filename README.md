# Action App

A cross-platform application with Flutter mobile and web apps, and a Node.js backend using Firebase.

## Project Structure

```
actionapp/
├── mobile/              # Flutter mobile app for users
│   ├── lib/
│   │   ├── core/        # Core utilities, themes, constants
│   │   └── features/    # Feature-based modules
│   │       ├── auth/
│   │       ├── profile/
│   │       └── orders/
│   └── pubspec.yaml
│
├── web/                 # Flutter web app for admin
│   ├── lib/
│   │   ├── core/        # Core utilities, themes, constants
│   │   └── features/    # Feature-based modules
│   │       ├── auth/
│   │       ├── dashboard/
│   │       ├── users/
│   │       └── reports/
│   └── pubspec.yaml
│
├── backend/             # Node.js backend
│   ├── controllers/     # Request handlers
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── middleware/      # Express middleware
│   ├── app.js           # Express app entry point
│   ├── package.json
│   └── .env             # Environment variables
│
└── firebase/            # Firebase configuration
    ├── firestore.rules
    ├── storage.rules
    └── firebase.json
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.3 or higher)
- Node.js (v18 or higher)
- Firebase account and project

### Mobile App Setup

```bash
cd mobile
flutter pub get
flutter run
```

### Web App Setup

```bash
cd web
flutter pub get
flutter run -d chrome
```

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your Firebase credentials
npm run dev
```

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Firestore Database and Storage
3. Download service account key and add to backend/.env
4. Deploy rules:
   ```bash
   cd firebase
   firebase deploy --only firestore:rules,storage:rules
   ```

## Features

### Mobile App
- User authentication
- User profile management
- Order management

### Web App (Admin)
- Admin authentication
- Dashboard
- User management
- Reports

### Backend
- RESTful API
- Firebase integration
- Authentication middleware
- User and order management

## License

MIT
